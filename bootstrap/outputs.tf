output "state_bucket_name" {
  description = "Paste this into envs/dev/backend.hcl."
  value       = aws_s3_bucket.state.bucket
}

output "region" {
  description = "Region of the state bucket."
  value       = var.region
}
