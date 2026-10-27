# HIPAA-Ready AWS Landing Zone (Terraform)

[![terraform-checks](https://github.com/ShabangTech/aws-hipaa-landing-zone/actions/workflows/terraform-checks.yml/badge.svg)](https://github.com/ShabangTech/aws-hipaa-landing-zone/actions/workflows/terraform-checks.yml)

A security-first AWS foundation built entirely with reusable Terraform modules. It sets up the guardrails a healthcare or other regulated team would expect before any workload goes in: encrypted audit logs, private networking, threat detection, and account-wide security defaults. Every change is format-checked, validated, and security-scanned in CI.

> **Status:** Phase 1 in progress. See the [roadmap](docs/ROADMAP.md).

## Architecture

```mermaid
flowchart LR
    subgraph Account["AWS account (us-east-1)"]
        subgraph VPC["VPC 10.20.0.0/16"]
            PUB["Public subnets x2<br/>(no auto public IPs)"]
            PRIV["Private subnets x2<br/>(no internet route)"]
        end
        CT["CloudTrail<br/>log file validation"]
        FL["VPC Flow Logs"]
        KMS["KMS key<br/>auto-rotation"]
        S3["Log archive bucket<br/>versioned, private, TLS-only"]
        BASE["Account guardrails<br/>S3 public block, EBS encryption"]
        OPT["Feature flags<br/>GuardDuty, Access Analyzer,<br/>multi-region trail"]
    end
    VPC --> FL --> S3
    CT --> S3
    KMS -. encrypts .-> S3
    GH["GitHub Actions<br/>fmt, validate, Checkov"] -. checks every change .-> Account
```

## What it builds

| Module | What it does |
|---|---|
| [`bootstrap`](bootstrap) | Versioned, encrypted, private S3 bucket for Terraform remote state, with native S3 state locking |
| [`log-archive`](modules/log-archive) | KMS key with rotation plus an S3 bucket that receives CloudTrail and VPC flow logs, locked to the services that write to it |
| [`network`](modules/network) | VPC across two availability zones, public and private subnets, flow logs, and a default security group with every rule removed |
| [`audit-trail`](modules/audit-trail) | CloudTrail with log file integrity validation, encrypted with the log archive key; multi-region behind a flag |
| [`security-baseline`](modules/security-baseline) | Account-wide S3 public access block and default EBS encryption, plus GuardDuty, IAM Access Analyzer and an IAM password policy behind feature flags |

### Works on both kinds of AWS account

New AWS sign-ups (since September 2026) create a free-plan **project** that blocks some services, including GuardDuty, IAM Access Analyzer and multi-region features. Rather than fork the code, those controls are **feature flags** that default to off:

```hcl
# envs/dev/terraform.tfvars, in a standard account or one with advanced features
enable_guardduty       = true
enable_access_analyzer = true
multi_region_trail     = true
```

Same modules, one file of settings per account type.

## How the controls map to HIPAA technical safeguards

This project is a learning lab, not a compliance certification. It shows how common HIPAA Security Rule safeguards translate into cloud controls.

| Safeguard | Control in this repo |
|---|---|
| Audit controls, §164.312(b) | CloudTrail on all regions, VPC flow logs |
| Integrity, §164.312(c)(1) | CloudTrail log file validation, S3 versioning |
| Encryption, §164.312(a)(2)(iv) | KMS-encrypted logs, default EBS encryption |
| Transmission security, §164.312(e)(1) | Bucket policies deny any request not using TLS |
| Access control, §164.312(a)(1) | Least-privilege bucket and key policies, account-wide public access block |
| Activity review, §164.308(a)(1)(ii)(D) | CloudTrail logs; GuardDuty findings and IAM Access Analyzer where the account allows (flags) |
| Password management, §164.308(a)(5)(ii)(D) | IAM password policy (14+ characters, rotation, no reuse), behind a flag |

## Cost guardrails

Designed to run at or near $0 on a new account:

- **No NAT gateway**, which would cost about $32 a month. Private subnets have no internet route.
- **GuardDuty** is off by default. Where available it has a 30-day free trial.
- **KMS** costs about $1 a month per key, covered by new-account credits.
- Run `terraform destroy` at the end of each session.

## Quick start

Full step-by-step instructions are in [docs/SETUP.md](docs/SETUP.md).

```bash
# 1. Create the state bucket (once)
cd bootstrap
terraform init && terraform apply

# 2. Deploy the dev environment
cd ../envs/dev
cp backend.hcl.example backend.hcl   # paste in the bucket name from step 1
terraform init -backend-config=backend.hcl
terraform plan
terraform apply

# 3. Tear down when finished
terraform destroy
```

## Repository layout

```
bootstrap/                 Remote state bucket (run once)
modules/
  log-archive/             KMS key and encrypted log bucket
  network/                 VPC, subnets, flow logs
  audit-trail/             CloudTrail
  security-baseline/       GuardDuty, Access Analyzer, account guardrails
envs/dev/                  Wires the modules together
.github/workflows/         CI: fmt, validate, Checkov
docs/                      Setup guide and roadmap
```

## Author

**ShabangTech**: CompTIA Security+, U.S. Army veteran, B.S. Information Technology (Security) in progress.
