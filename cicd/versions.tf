terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37"
    }
  }

  # Same state bucket as envs/dev, its own key:
  # terraform init -backend-config=../envs/dev/backend.hcl
  backend "s3" {
    key          = "cicd/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aws-hipaa-landing-zone"
      ManagedBy = "terraform"
      Component = "cicd"
    }
  }
}
