# Audit trail: a CloudTrail that records every API call in the account,
# encrypted with the log archive KMS key, with log file integrity validation
# turned on. Single-region by default (AWS "projects" accounts don't support
# multi-region features); set multi_region = true in a standard account.
#
# Known gap: since November 2021 CloudTrail delivers global service events
# (IAM, STS, CloudFront) only to multi-Region trails or trails in us-east-1.
# A single-region trail in us-east-2 therefore does NOT record IAM changes.
# Standard accounts close the gap with multi_region = true.

resource "aws_cloudtrail" "this" {
  #checkov:skip=CKV2_AWS_10:CloudWatch Logs delivery is a feature flag (cloudwatch_logs_enabled), off by default
  #checkov:skip=CKV_AWS_252:SNS notifications for log delivery are not needed for a lab
  #checkov:skip=CKV_AWS_67:Multi-region is a variable; projects accounts block it, standard accounts set multi_region = true
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = var.log_bucket_name
  s3_key_prefix                 = "cloudtrail"
  kms_key_id                    = var.kms_key_arn
  is_multi_region_trail         = var.multi_region
  include_global_service_events = true
  enable_log_file_validation    = true

  # Optional near-real-time copy for detections (see cloudwatch.tf).
  cloud_watch_logs_group_arn = var.cloudwatch_logs_enabled ? "${aws_cloudwatch_log_group.trail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.cloudwatch_logs_enabled ? aws_iam_role.trail_to_cloudwatch[0].arn : null

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  # CloudTrail checks the role can write before it saves the trail.
  depends_on = [aws_iam_role_policy.trail_to_cloudwatch]
}
