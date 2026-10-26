# Setup guide (Phase 0)

Never paste passwords, MFA codes, or access keys into chats, issues, or commits.

## 1. AWS account

1. Create an account at aws.amazon.com and pick the **Free plan**.
2. Sign in as root, then go to **Security credentials** and **assign MFA**.
3. Go to **Billing**, then **Budgets**. Create a **zero-spend budget** and a **$5 monthly budget**, both emailing you.

## 2. Admin user (stop using root)

1. In the AWS console, open **IAM Identity Center** and click **Enable** (region: us-east-1).
2. **Users**, then **Add user**: create yourself (for example `my-admin`) and accept the invitation email.
3. **Permission sets**, then **Create**: choose the predefined **AdministratorAccess**.
4. **AWS accounts**: select your account, then **Assign users**, and pick your user and the AdministratorAccess set.
5. Copy the **AWS access portal URL** from the Identity Center dashboard. You need it in step 4.
6. Sign out of root. From now on, sign in only through the portal URL.

## 3. Install the tools

**Windows** (PowerShell):

```powershell
winget install Hashicorp.Terraform
winget install Amazon.AWSCLI
winget install Git.Git
winget install Microsoft.VisualStudioCode
```

**Mac** (Terminal, with Homebrew):

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform awscli git
brew install --cask visual-studio-code
```

Close and reopen the terminal, then check:

```bash
terraform -version
aws --version
git --version
```

## 4. Sign in from the terminal

```bash
aws configure sso
```

- SSO session name: `hlz`
- SSO start URL: the access portal URL from step 2
- SSO region: `us-east-1`
- Accept the default scope, approve in the browser, and pick your account and role
- Default client region: `us-east-1`, output format: `json`
- Profile name: `hlz-admin`

Test it:

```bash
aws sts get-caller-identity --profile hlz-admin
```

Tell Terraform which profile to use for this terminal session:

```powershell
$env:AWS_PROFILE = "hlz-admin"     # Windows PowerShell
```

```bash
export AWS_PROFILE=hlz-admin       # Mac
```

When the sign-in expires, run `aws sso login --profile hlz-admin`.

## 5. Get the code and create the state bucket

```bash
git clone https://github.com/ShabangTech/aws-hipaa-landing-zone.git
cd aws-hipaa-landing-zone/bootstrap
terraform init
terraform apply
```

Type `yes` when asked. Copy the `state_bucket_name` it prints.

## 6. Deploy the dev environment (Phase 1)

```bash
cd ../envs/dev
cp backend.hcl.example backend.hcl
```

Edit `backend.hcl` and paste in your bucket name. Then:

```bash
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## 7. Tear down

```bash
terraform destroy          # in envs/dev
cd ../../bootstrap
terraform destroy          # only when you are done with the project
```
