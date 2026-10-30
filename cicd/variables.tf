variable "region" {
  description = "AWS region (the account's home region)."
  type        = string
  default     = "us-east-2"
}

variable "name_prefix" {
  description = "Prefix used by the landing zone's resource names (the apply role may only manage IAM roles with it)."
  type        = string
  default     = "hlz"
}

variable "github_repo" {
  description = "The only GitHub repository allowed to use these roles (owner/name)."
  type        = string
  default     = "ShabangTech/aws-hipaa-landing-zone"
}

variable "deploy_environment" {
  description = "GitHub environment whose approved jobs may use the apply role."
  type        = string
  default     = "production"
}

variable "state_bucket" {
  description = "The Terraform state bucket created by bootstrap (same as backend.hcl)."
  type        = string
}

variable "create_oidc_provider" {
  description = "Create GitHub's OIDC provider. Set false if the account already has one for token.actions.githubusercontent.com."
  type        = bool
  default     = true
}
