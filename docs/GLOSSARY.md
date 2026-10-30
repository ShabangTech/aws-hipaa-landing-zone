# Glossary

Every acronym used in this landing zone and in the
[aws-cloud-detection-lab](https://github.com/ShabangTech/aws-cloud-detection-lab) built on top of it.

## Names on the resources

| Acronym | Means |
|---------|-------|
| cdl | Cloud Detection Lab, the prefix on everything this repo creates (`cdl-sg-remediator`, `cdl-security-alerts`) |
| hlz | HIPAA Landing Zone, the prefix on everything the landing zone creates (`hlz-trail`, `/hlz/cloudtrail`) |
| sg | Security Group, AWS's virtual firewall (`cdl-sg-remediator` = the lab's security group fixer) |
| D01 to D09 | Detection 1 to 9 in the detection lab (see [DETECTIONS.md](https://github.com/ShabangTech/aws-cloud-detection-lab/blob/main/docs/DETECTIONS.md)) |

## AWS services

| Acronym | Means |
|---------|-------|
| AWS | Amazon Web Services |
| IAM | Identity and Access Management: users, roles and permissions |
| STS | Security Token Service, which issues temporary credentials |
| SNS | Simple Notification Service, which sends the alert emails |
| S3 | Simple Storage Service, where the logs are archived |
| KMS | Key Management Service, which holds the encryption keys |
| VPC | Virtual Private Cloud, the private network |
| EC2 | Elastic Compute Cloud: servers, and where security groups live |
| SCP | Service Control Policy, an organization-wide guardrail that can deny API calls; an explicit deny in one beats every allow (it blocked S3 bucket names and the GitHub OIDC provider in this project) |
| ARN | Amazon Resource Name, the unique ID of any AWS resource |
| CLI | Command Line Interface (the `aws` command) |
| OIDC | OpenID Connect, which lets GitHub Actions sign in to AWS without stored keys (see [CICD.md](CICD.md)) |
| JWT | JSON Web Token, the signed token GitHub hands a workflow run; its `sub` (subject) says which repo, branch or environment it came from |

## Security terms

| Acronym | Means |
|---------|-------|
| MITRE ATT&CK | MITRE's catalog of Adversarial Tactics, Techniques & Common Knowledge; each T-number (like T1562.007) is one technique |
| SOC | Security Operations Center |
| SIEM | Security Information and Event Management (for example, Splunk) |
| HIPAA | Health Insurance Portability and Accountability Act |
| PHI | Protected Health Information |
| MFA | Multi-Factor Authentication |
| SSH | Secure Shell, remote login on port 22 |
| RDP | Remote Desktop Protocol, port 3389 |
| CIDR | Classless Inter-Domain Routing, notation for IP ranges; `0.0.0.0/0` means the entire internet |
| OSINT | Open-Source Intelligence |

## Tools and practices

| Acronym | Means |
|---------|-------|
| IaC | Infrastructure as Code, which is what Terraform does |
| CI/CD | Continuous Integration / Continuous Delivery (the GitHub Actions checks and the deploy pipeline) |
| PR | Pull Request: a proposed change on GitHub; the pipeline posts a `terraform plan` on each one |
| GitHub environment | A named deploy target (here `production`) that can require a person's approval before a job runs |
| Artifact | A file one workflow job saves for a later one (the reviewed `tfplan` handed to the apply job) |
