# Roadmap

About 22 to 27 hours total, roughly 2 to 3 weeks at 1 to 2 hours a day.

## Phase 0: Setup (2 to 3 hours)
- [ ] AWS account on the Free plan, root MFA on, zero-spend and $5 budgets
- [ ] IAM Identity Center admin user; stop using root
- [ ] Install Terraform, AWS CLI v2, Git, and VS Code
- [ ] Clone this repo and sign in with `aws configure sso`
- [ ] Deploy `bootstrap` (remote state bucket)

## Phase 1: Core modules (8 to 10 hours)
- [x] `log-archive`: KMS key and encrypted log bucket
- [x] `network`: VPC, subnets, flow logs, locked default security group
- [x] `audit-trail`: multi-region CloudTrail with log validation
- [x] `security-baseline`: GuardDuty, Access Analyzer, account guardrails
- [ ] Deploy `envs/dev`, confirm logs arrive in the bucket, screenshot the results
- [ ] Destroy and redeploy once to prove it is repeatable

## Phase 2: CI/CD pipeline (4 to 5 hours)
- [x] GitHub Actions: `terraform fmt`, `validate`, Checkov
- [ ] GitHub OIDC provider and deploy role in AWS (no stored access keys)
- [ ] `terraform plan` on every pull request, posted as a comment
- [ ] Manual-approval `apply` job on `main`

## Phase 3: Auto-remediation (5 to 6 hours)
- [ ] EventBridge rule for security group changes
- [ ] Python Lambda that removes any rule opening SSH (port 22) to `0.0.0.0/0`
- [ ] SNS email alert when a fix happens
- [ ] Test it live and record the before and after

## Phase 4: Polish (2 to 3 hours)
- [ ] Architecture diagram image for the README
- [ ] Screenshots: CloudTrail, GuardDuty, a passing pipeline, an auto-fix
- [ ] Short write-up of lessons learned
- [ ] Update resume bullets to past tense and add the repo link
