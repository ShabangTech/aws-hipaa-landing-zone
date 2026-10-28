# Roadmap

About 22 to 27 hours total, roughly 2 to 3 weeks at 1 to 2 hours a day.

## Phase 0: Setup (2 to 3 hours)
- [x] AWS account on the Free plan (projects sign-up, paid for with AWS credits)
- [x] MFA on the Builder ID sign-in (settings.aws.com), tested at sign-in
- [x] Install Terraform, AWS CLI v2.32+, Git, and VS Code
- [x] Sign in with `aws login` and create the `hlz` profile for Terraform
- [x] Clone this repo
- [x] Deploy `bootstrap` (remote state bucket in us-east-2, the project home region)

## Phase 1: Core modules (8 to 10 hours)
- [x] `log-archive`: KMS key and encrypted log bucket
- [x] `network`: VPC, subnets, flow logs, locked default security group
- [x] `audit-trail`: CloudTrail with log validation (multi-region behind a flag)
- [x] `security-baseline`: account guardrails, with GuardDuty and Access Analyzer as feature flags
- [x] Feature flags for services the projects account blocks (GuardDuty, Access Analyzer, multi-region trail)
- [x] Deploy `envs/dev`, confirm logs arrive in the bucket, screenshot the results ([build log](BUILD_LOG.md))
- [x] Destroy cleanly (26 resources removed)
- [x] Redeploy from scratch and destroy again to prove it is repeatable

## Phase 2: CI/CD pipeline (4 to 5 hours)
- [x] GitHub Actions: `terraform fmt`, `validate`, Checkov
- [ ] GitHub OIDC provider and deploy role in AWS (no stored access keys)
- [ ] `terraform plan` on every pull request, posted as a comment
- [ ] Manual-approval `apply` job on `main`

## Phase 3: Auto-remediation (5 to 6 hours)
Built and tested in the companion [aws-cloud-detection-lab](https://github.com/ShabangTech/aws-cloud-detection-lab),
which runs on this landing zone (`cloudtrail_to_cloudwatch = true`).
- [x] EventBridge rule for security group changes
- [x] Python Lambda that removes any rule opening SSH (port 22) to `0.0.0.0/0`
- [x] SNS email alert when a fix happens
- [x] Test it live and record the before and after (closed in 7 to 9 seconds;
      [results](https://github.com/ShabangTech/aws-cloud-detection-lab/blob/main/docs/RESULTS.md))

## Phase 4: Polish (2 to 3 hours)
- [ ] Architecture diagram image for the README
- [ ] Screenshots: CloudTrail, GuardDuty, a passing pipeline, an auto-fix
- [x] Short write-up of lessons learned (in the [build log](BUILD_LOG.md#lessons))
- [x] Update resume bullets to past tense and add the repo link
