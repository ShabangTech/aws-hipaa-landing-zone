variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket that receives CloudTrail logs."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudTrail logs."
  type        = string
}
