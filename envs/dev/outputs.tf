output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.network.vpc_id
}

output "log_archive_bucket" {
  description = "Bucket holding CloudTrail and VPC flow logs."
  value       = module.log_archive.bucket_name
}

output "cloudtrail_arn" {
  description = "ARN of the account trail."
  value       = module.audit_trail.trail_arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (null when disabled)."
  value       = module.security_baseline.guardduty_detector_id
}
