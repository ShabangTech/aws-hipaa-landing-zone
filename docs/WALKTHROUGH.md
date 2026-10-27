# Terraform walkthrough (Windows)

Every step from a new AWS account to a deployed, verified, and torn-down landing zone. Each step lists what to run, what it does, and how to confirm it worked. Run commands in **PowerShell** unless noted.

> **Golden rule:** never paste passwords, MFA codes, or access keys into chats, issues, commits, or screenshots.

---

## Which kind of AWS account do you have?

Since September 2026, new AWS sign-ups create a **project** owned by an **AWS Builder ID** instead of a classic account with a root user. This guide is written for that newer kind (free plan). Differences that matter here:

| | Projects account (this guide) | Standard account |
|---|---|---|
| Owner | AWS Builder ID, no root user | Root user email |
| MFA | settings.aws.com | IAM, Security credentials |
| Terminal sign-in | `aws login` | `aws login` or IAM Identity Center |
| GuardDuty, Access Analyzer, multi-region trail | Blocked: leave the flags off | Set the flags to `true` |
| Spend protection | Spend limit pauses the project | Budgets only |

---

## Part 1: Account (one time)

### Step 1. Create the account
- Sign up at aws.amazon.com. You'll land on Console Home with a project (for example "Idea Launchpad").
- **Check:** your account menu (top right) shows **Free plan status** with credits and days remaining.

### Step 2. Turn on MFA
- Go to **settings.aws.com** and turn on multi-factor authentication for your sign-in, using an authenticator app.
- **What it does:** your Builder ID owns the account, so this is the login that most needs protecting.
- **Check:** signing out and back in asks for an MFA code.

### Step 3. Note your region
- In the console, look at the address bar for `region=`, for example `region=us-east-1`.
- **What it does:** Terraform must deploy to the region your project uses. This repo defaults to `us-east-1`. If yours is different, change `region` in `bootstrap/variables.tf` and `envs/dev/variables.tf`.

---

## Part 2: Your computer (one time)

### Step 4. Install the tools
Open **PowerShell as Administrator**:

```powershell
winget install Hashicorp.Terraform
winget install Amazon.AWSCLI
winget install Git.Git
winget install Microsoft.VisualStudioCode
```

Close PowerShell and open a new window, then check:

```powershell
terraform -version
aws --version
git --version
```

- **Check:** all three print a version, and `aws --version` shows **aws-cli/2.32 or later** (needed for `aws login`). If it's older: `winget upgrade Amazon.AWSCLI`.

### Step 5. Configure Git

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

In VS Code, press `Ctrl+Shift+X` and install the **HashiCorp Terraform** extension.

### Step 6. Connect the AWS CLI to your account

```powershell
aws configure set region us-east-1
aws login
```

A browser opens. Sign in the same way you sign in to the console and approve. Then test:

```powershell
aws sts get-caller-identity
```

You should see your 12-digit account ID and an ARN.

### Step 7. Give Terraform a profile it can use

`aws login` credentials work in the AWS CLI. To be sure Terraform can use them too, create a second profile, `hlz`, that asks the CLI for fresh credentials every time:

```powershell
aws configure set credential_process "aws configure export-credentials --profile default --format process" --profile hlz
aws configure set region us-east-1 --profile hlz
aws sts get-caller-identity --profile hlz
```

- **Check:** the last command shows the same account ID as Step 6.
- **Why two profiles:** putting `credential_process` on the `default` profile breaks `aws login`, and `--profile default` inside it stops the `hlz` profile from calling itself in a loop.

---

## Part 3: Every work session

### Step 8. Sign in and pick the profile

```powershell
aws login
$env:AWS_PROFILE = "hlz"
```

- **What it does:** refreshes your sign-in and tells Terraform to use the `hlz` profile in this window.
- **Tip:** `$env:AWS_PROFILE` only lasts for this PowerShell window. Set it again in any new window.

### Step 9. Get the code (first time only)

```powershell
cd $HOME\Documents
git clone https://github.com/ShabangTech/aws-hipaa-landing-zone.git
cd aws-hipaa-landing-zone
code .
```

Afterward, pull the latest changes at the start of each session:

```powershell
git pull
```

---

## Part 4: Deploy

### Step 10. Create the state bucket (bootstrap, one time)

```powershell
cd bootstrap
terraform init
terraform plan
terraform apply
```

Type `yes` when asked.

- **What it does:** creates the private, encrypted, versioned S3 bucket where Terraform remembers what it built. Bootstrap itself keeps its small state file locally, in the `bootstrap` folder (git-ignored).
- **Check:** the output shows `state_bucket_name = "hlz-tfstate-<your account id>"`. Copy it.

### Step 11. Point the dev environment at the state bucket

```powershell
cd ..\envs\dev
Copy-Item backend.hcl.example backend.hcl
code backend.hcl
```

Replace the example bucket name with yours and save. `backend.hcl` is git-ignored, so your account ID never lands on GitHub.

### Step 12. Initialize, plan, and apply

```powershell
terraform init -backend-config=backend.hcl
terraform fmt -recursive ..\..
terraform validate
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
```

| Command | What it does |
|---|---|
| `init` | Downloads the AWS provider and connects to the remote state bucket |
| `fmt` | Fixes formatting so CI does not fail |
| `validate` | Catches typos and wrong argument names before touching AWS |
| `plan -out` | Shows exactly what will be created and saves that plan |
| `apply dev.tfplan` | Builds exactly what the saved plan showed, nothing else |

- **Check:** the plan lists about 35 resources to add, and apply ends with `Apply complete!` and four outputs.

---

## Part 5: Verify it worked (and take screenshots)

Screenshots go in `docs/images/` for the README. Blur your account ID.

| What to check | Where in the console | What you should see |
|---|---|---|
| VPC and subnets | VPC, then Your VPCs | `hlz-vpc` with 2 public and 2 private subnets |
| Flow logs | VPC, `hlz-vpc`, Flow logs tab | Active, destination is the log archive bucket |
| CloudTrail | CloudTrail, then Trails | `hlz-trail`, log validation on, KMS encrypted |
| Logs arriving | S3, `hlz-log-archive-...` | `cloudtrail/` and `vpc-flow-logs/` folders (allow 5 to 15 minutes) |
| Encryption | KMS, Customer managed keys | `alias/hlz-log-archive`, rotation enabled |
| Guardrails | S3, Block Public Access settings for this account | All four settings on |

**GuardDuty and Access Analyzer** are off on projects accounts. In a standard account, set `enable_guardduty = true` and `enable_access_analyzer = true` in `envs/dev/terraform.tfvars`, apply, and generate sample findings with `aws guardduty create-sample-findings --detector-id (terraform output -raw guardduty_detector_id)`.

---

## Part 6: Tear down

At the end of every session:

```powershell
cd envs\dev
terraform destroy
```

Only when the whole project is finished:

```powershell
cd ..\..\bootstrap
terraform destroy
```

- **What it does:** deletes everything Terraform created, so nothing keeps running.
- **Check:** `terraform state list` in `envs\dev` prints nothing. The KMS key enters a 7-day waiting period before deletion, which is normal.

---

## Part 7: Saving your work to GitHub

```powershell
git status
git add -A
git commit -m "Short description of what changed"
git push
```

Then open the repo's **Actions** tab. All three checks (Format, Validate, Checkov) should show a green check.

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `terraform` is not recognized | PATH not refreshed after install | Open a new PowerShell window or restart |
| `ExpiredToken` or `Your session has expired` | Sign-in timed out | `aws login` |
| `No valid credential sources found` | Profile not set in this window | `$env:AWS_PROFILE = "hlz"` |
| `aws: error: argument command: Invalid choice ... login` | AWS CLI older than 2.32 | `winget upgrade Amazon.AWSCLI`, then open a new window |
| `AccessDenied` mentioning a service control policy | Your account type blocks that service or region | Check the region (Step 3); keep blocked features' flags off |
| `BucketAlreadyExists` | Bucket names are global | Change `name_prefix` in `variables.tf` |
| `Error acquiring the state lock` | A previous run was interrupted | Wait a minute and retry; if stuck, `terraform force-unlock <LOCK_ID>` |
| `InsufficientS3BucketPolicyException` on CloudTrail | Trail created before the bucket policy | Run `terraform apply` again |
| Free plan blocks a service | Some services need the paid plan | Note it in the roadmap; upgrade only if needed |
| CI Format check fails | Code not formatted | `terraform fmt -recursive` from the repo root, then commit |

---

## What's next

- **Phase 2:** GitHub connects to AWS through OIDC (no stored keys), runs `terraform plan` on pull requests, and applies on approval.
- **Phase 3:** EventBridge and a Python Lambda automatically remove any security group rule that opens SSH to the internet, then email you.
- **Phase 4:** README screenshots, diagram, lessons learned, and resume update.
