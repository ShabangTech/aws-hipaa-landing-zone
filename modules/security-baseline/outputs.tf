output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector, or null when disabled."
  value       = try(aws_guardduty_detector.this[0].id, null)
}

output "access_analyzer_arn" {
  description = "ARN of the IAM Access Analyzer."
  value       = aws_accessanalyzer_analyzer.this.arn
}
