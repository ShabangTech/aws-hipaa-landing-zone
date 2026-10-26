# Terraform walkthrough (Windows)

Every step from an empty AWS account to a deployed, verified, and torn-down landing zone. Each step lists what to run, what it does, and how to confirm it worked. Run commands in **PowerShell** unless noted.

> **Golden rule:** never paste passwords, MFA codes, or access keys into chats, issues, commits, or screenshots.

---

## Part 1: Account and access (one time)

### Step 1. Create the AWS account
- Sign up at aws.amazon.com and choose the **Free plan**.
- **What it does:** gives you a sandbox with credits that cannot be charged for 6 months.
- **Check:** you can sign in to the AWS console as the root user.

### Step 2. Protect the root user
- Console, then account menu (top right), then **Security credentials**, then **Assign MFA device**. Use an authenticator app.
- **What it does:** root can do anything, including close the account. MFA stops a stolen password from being enough.
- **Check:** signing out and back in asks for an MFA code.

### Step 3. Set up budget alerts
- **Billing and Cost Management**, then **Budgets**, then **Create budget**.
- Create a **Zero spend budget** (template) and a **Monthly cost budget** of **$5**. Use your email for both.
- **What it does:** emails you the moment anything starts costing money.
- **Check:** both budgets appear in the Budgets list.

### Step 4. Create your admin user in IAM Identity Center
1. Search the console for **IAM Identity Center** and click **Enable** (region: **us-east-1**).
2. **Users**, then **Add user**, for example `my-admin`. Accept the email invitation and set a password and MFA.
3. **Permission sets**, then **Create permission set**, then **Predefined**, then **AdministratorAccess**.
4. **AWS accounts**, select your account, then **Assign users or groups**, and choose your user and the AdministratorAccess set.
5. Copy the **AWS access portal URL** from the Identity Center dashboard.
- **What it does:** creates a day-to-day admin with short-lived credentials, so you stop using root and never need long-lived access keys.
- **Check:** the portal URL shows your account with an **AdministratorAccess** role. Sign out of root for good.

---

## Part 2: Your computer (one time)

### Step 5. Install the tools
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

- **Check:** all three print a version. If one says "not recognized," restart the computer.

### Step 6. Configure Git

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

In VS Code, press `Ctrl+Shift+X` and install the **HashiCorp Terraform** extension.

### Step 7. Connect the AWS CLI to your admin user

```powershell
aws configure sso
```

| Prompt | Answer |
|---|---|
| SSO session name | `hlz` |
| SSO start URL | your access portal URL from Step 4 |
| SSO region | `us-east-1` |
| SSO registration scopes | press Enter (default) |
| (browser opens) | sign in and click **Allow** |
| Account / role | your account, **AdministratorAccess** |
| Default client Region | `us-east-1` |
| CLI default output format | `json` |
| Profile name | `hlz-admin` |

- **What it does:** lets the terminal borrow temporary credentials from your admin user.
- **Check:**

```powershell
aws sts get-caller-identity --profile hlz-admin
```

You should see your 12-digit account ID and a role ARN containing `AdministratorAccess`.

---

## Part 3: Every work session

### Step 8. Sign in and pick the profile

```powershell
aws sso login --profile hlz-admin
$env:AWS_PROFILE = "hlz-admin"
```

- **What it does:** refreshes your temporary credentials (they last about 8 hours) and tells Terraform which profile to use in this window.
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

- **Check:** the plan lists about 40 resources to add, and apply ends with `Apply complete!` and four outputs.

---

## Part 5: Verify it worked (and take screenshots)

Screenshots go in `docs/images/` for the README. Blur your account ID.

| What to check | Where in the console | What you should see |
|---|---|---|
| VPC and subnets | VPC, then Your VPCs | `hlz-vpc` with 2 public and 2 private subnets |
| Flow logs | VPC, `hlz-vpc`, Flow logs tab | Active, destination is the log archive bucket |
| CloudTrail | CloudTrail, then Trails | `hlz-trail`, multi-region, log validation on, KMS encrypted |
| Logs arriving | S3, `hlz-log-archive-...` | `cloudtrail/` and `vpc-flow-logs/` folders (allow 5 to 15 minutes) |
| Encryption | KMS, Customer managed keys | `alias/hlz-log-archive`, rotation enabled |
| GuardDuty | GuardDuty, Summary | Enabled, no findings yet |
| Access Analyzer | IAM, Access analyzer | `hlz-access-analyzer` active |
| Guardrails | S3, Block Public Access settings for this account | All four settings on |

**Optional security test:** ask GuardDuty for sample findings, then view them in the console:

```powershell
$detector = terraform output -raw guardduty_detector_id
aws guardduty create-sample-findings --detector-id $detector
```

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
| `ExpiredToken` or `The SSO session has expired` | Temporary credentials timed out | `aws sso login --profile hlz-admin` |
| `No valid credential sources found` | Profile not set in this window | `$env:AWS_PROFILE = "hlz-admin"` |
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
