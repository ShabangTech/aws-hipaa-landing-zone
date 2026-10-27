# Security baseline: account-wide guardrails.
#
# Always on (free, available on every account type):
#   - account-wide S3 Block Public Access
#   - default EBS encryption
#
# Feature flags (off by default so the module works on AWS's newer
# "projects" accounts, which block these services; turn them on in a
# standard account or one with advanced features activated):
#   - enable_guardduty         threat detection (30-day trial, then paid)
#   - enable_access_analyzer   flags resources shared outside the account
#   - enable_password_policy   IAM password rules (only matters when IAM
#                              users can sign in to the console)

resource "aws_guardduty_detector" "this" {
  #checkov:skip=CKV2_AWS_3:Single-account lab with no AWS Organization
  count = var.enable_guardduty ? 1 : 0

  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# Flags any resource shared outside the account.
resource "aws_accessanalyzer_analyzer" "this" {
  count = var.enable_access_analyzer ? 1 : 0

  analyzer_name = "${var.name_prefix}-access-analyzer"
  type          = "ACCOUNT"
}

# Blocks public S3 access for every bucket in the account.
resource "aws_s3_account_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Every new EBS volume is encrypted automatically.
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}

resource "aws_iam_account_password_policy" "this" {
  count = var.enable_password_policy ? 1 : 0

  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  max_password_age               = 90
}
