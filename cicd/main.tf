# CI/CD access for GitHub Actions, with no stored AWS keys.
#
# GitHub signs a short-lived token (OIDC) for each workflow run. AWS trusts GitHub's identity
# provider, checks the token says it came from THIS repository (and from the right branch or
# environment), and hands back temporary credentials for one role, valid for one hour at most.
#
#   plan role   read-only + the state lock. Used by pull requests and pushes to main.
#   apply role  can change only what the landing zone is made of. Used ONLY by jobs in the
#               "production" GitHub environment, which needs a person's approval to run.

data "aws_caller_identity" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  oidc_host     = "token.actions.githubusercontent.com"
  provider_arn  = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${local.account_id}:oidc-provider/${local.oidc_host}"
  state_bucket  = "arn:aws:s3:::${var.state_bucket}"
  dev_state_key = "${local.state_bucket}/dev/*"
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url            = "https://${local.oidc_host}"
  client_id_list = ["sts.amazonaws.com"]
  # No thumbprint: AWS validates GitHub's certificate against its own trusted CAs.
}

# --- who may assume each role ---------------------------------------------------------------------

data "aws_iam_policy_document" "plan_trust" {
  statement {
    sid     = "GitHubPullRequestsAndMain"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only this repository, and only pull requests or the main branch.
    condition {
      test     = "StringLike"
      variable = "${local.oidc_host}:sub"
      values = [
        "repo:${var.github_repo}:pull_request",
        "repo:${var.github_repo}:ref:refs/heads/main",
      ]
    }
  }
}

data "aws_iam_policy_document" "apply_trust" {
  statement {
    sid     = "GitHubApprovedProductionJobsOnly"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # A job only gets this subject when it runs in the protected environment, i.e. after approval.
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = ["repo:${var.github_repo}:environment:${var.deploy_environment}"]
    }
  }
}

# --- the plan role: look, don't touch -------------------------------------------------------------

resource "aws_iam_role" "plan" {
  name                 = "${var.name_prefix}-github-plan"
  description          = "GitHub Actions: terraform plan for ${var.github_repo} (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_read_only" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Plan needs to read the state and take the lock (a .tflock object next to the state file).
data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [local.state_bucket]
  }

  statement {
    sid       = "ReadWriteDevStateAndLock"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [local.dev_state_key]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "terraform-state"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.state_access.json
}

# --- the apply role: only what the landing zone is made of ---------------------------------------

data "aws_iam_policy_document" "apply" {
  #checkov:skip=CKV_AWS_356:The landing zone creates and deletes these resources, so their ARNs are not known in advance
  #checkov:skip=CKV_AWS_111:Write access is limited to the services the landing zone uses and to an approved job
  #checkov:skip=CKV_AWS_109:Permissions management is limited to IAM roles named with the project prefix
  #checkov:skip=CKV_AWS_107:No credentials are exposed: the role only exists for one approved workflow run
  #checkov:skip=CKV2_AWS_40:Full access is scoped to the landing zone's services, not to the account

  # S3: only the project's own buckets (the log archive), plus the account-level public access
  # block and the bucket list Terraform needs.
  statement {
    sid       = "ProjectBucketsOnly"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.name_prefix}-*", "arn:aws:s3:::${var.name_prefix}-*/*"]
  }

  statement {
    sid       = "AccountLevelS3Settings"
    actions   = ["s3:GetAccountPublicAccessBlock", "s3:PutAccountPublicAccessBlock", "s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  # The other services the four modules use (log-archive, network, audit-trail, security-baseline).
  statement {
    sid = "LandingZoneServices"
    actions = [
      "kms:*",
      "cloudtrail:*",
      "logs:*",
      "ec2:*",
      "guardduty:*",
      "access-analyzer:*",
      "sts:GetCallerIdentity",
    ]
    resources = ["*"]
  }

  # IAM: only the project's own roles (e.g. hlz-trail-to-cloudwatch), and only handed to CloudTrail.
  statement {
    sid = "ProjectRolesOnly"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole", "iam:UpdateRole", "iam:TagRole", "iam:UntagRole",
      "iam:PutRolePolicy", "iam:GetRolePolicy", "iam:DeleteRolePolicy", "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies", "iam:ListInstanceProfilesForRole", "iam:UpdateAssumeRolePolicy",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.name_prefix}-*"]
  }

  statement {
    sid       = "PassProjectRolesToCloudTrail"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${var.name_prefix}-*"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    sid       = "AccountPasswordPolicy"
    actions   = ["iam:GetAccountPasswordPolicy", "iam:UpdateAccountPasswordPolicy", "iam:DeleteAccountPasswordPolicy"]
    resources = ["*"]
  }

  # GuardDuty and Access Analyzer create their own service-linked roles the first time.
  statement {
    sid       = "ServiceLinkedRoles"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["guardduty.amazonaws.com", "access-analyzer.amazonaws.com"]
    }
  }

  # Hard stop: this role can never change the CI/CD access itself.
  statement {
    sid    = "NeverTouchCICDAccess"
    effect = "Deny"
    actions = [
      "iam:*OpenIDConnectProvider*",
      "iam:CreateUser", "iam:CreateAccessKey", "iam:AttachUserPolicy", "iam:PutUserPolicy",
    ]
    resources = ["*"]
  }

  statement {
    sid     = "NeverTouchTheGitHubRoles"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      "arn:aws:iam::${local.account_id}:role/${var.name_prefix}-github-*",
    ]
  }
}

resource "aws_iam_role" "apply" {
  name                 = "${var.name_prefix}-github-apply"
  description          = "GitHub Actions: terraform apply / destroy for ${var.github_repo} (approved production jobs only)"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = 3600
}

# Reading is harmless and keeps refresh / destroy from tripping over a missing Describe/Get.
resource "aws_iam_role_policy_attachment" "apply_read_only" {
  role       = aws_iam_role.apply.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy" "apply" {
  name   = "landing-zone-deploy"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.apply.json
}

resource "aws_iam_role_policy" "apply_state" {
  name   = "terraform-state"
  role   = aws_iam_role.apply.id
  policy = data.aws_iam_policy_document.state_access.json
}
