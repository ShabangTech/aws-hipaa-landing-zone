# Setup guide

The full, step-by-step guide is in [WALKTHROUGH.md](WALKTHROUGH.md), Parts 1 to 3.

Quick version (Windows PowerShell, AWS "projects" account):

```powershell
# One time
winget install Hashicorp.Terraform
winget install Amazon.AWSCLI          # needs 2.32+ for aws login
winget install Git.Git
aws configure set region us-east-1
aws login
aws configure set credential_process "aws configure export-credentials --profile default --format process" --profile hlz
aws configure set region us-east-1 --profile hlz

# Every session
aws login
$env:AWS_PROFILE = "hlz"
```

Never paste passwords, MFA codes, or access keys into chats, issues, or commits.
