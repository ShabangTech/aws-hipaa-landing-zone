# Bootstrap: creates the S3 bucket that stores Terraform state for every
# other environment. Run this once, with local state, before anything else.

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.37" # 6.37+ supports S3 account-regional namespaces
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "aws-hipaa-landing-zone"
      ManagedBy = "terraform"
      Component = "bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is out of scope for a single-account lab
  #checkov:skip=CKV_AWS_18:Access logging on the state bucket is not needed for a lab
  #checkov:skip=CKV2_AWS_62:Event notifications are not needed for the state bucket
  #checkov:skip=CKV_AWS_145:SSE-S3 is used for state to avoid a dedicated KMS key cost
  # Account-regional namespace (S3, March 2026): the name is reserved for this
  # account and region, so nobody else can take it.
  bucket           = "${var.name_prefix}-tfstate-${data.aws_caller_identity.current.account_id}-${var.region}-an"
  bucket_namespace = "account-regional"

  force_destroy = var.force_destroy
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "state" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.state.arn,
      "${aws_s3_bucket.state.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.state.json

  depends_on = [aws_s3_bucket_public_access_block.state]
}
