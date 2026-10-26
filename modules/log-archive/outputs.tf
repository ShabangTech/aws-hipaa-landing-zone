output "bucket_name" {
  description = "Name of the log archive bucket."
  value       = aws_s3_bucket.logs.bucket
}

output "bucket_arn" {
  description = "ARN of the log archive bucket."
  value       = aws_s3_bucket.logs.arn
}

output "kms_key_arn" {
  description = "ARN of the KMS key that encrypts the logs."
  value       = aws_kms_key.logs.arn
}

output "bucket_policy_id" {
  description = "Exposed so dependent modules can wait for the bucket policy."
  value       = aws_s3_bucket_policy.logs.id
}
