output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group receiving the trail, or null when disabled."
  value       = try(aws_cloudwatch_log_group.trail[0].name, null)
}
