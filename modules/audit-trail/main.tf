# Audit trail: a CloudTrail that records every API call in the account,
# encrypted with the log archive KMS key, with log file integrity validation
# turned on. Single-region by default (AWS "projects" accounts don't support
# multi-region features); set multi_region = true in a standard account.

resource "aws_cloudtrail" "this" {
  #checkov:skip=CKV2_AWS_10:CloudWatch Logs delivery is deferred to Phase 3 to keep costs near $0
  #checkov:skip=CKV_AWS_252:SNS notifications for log delivery are not needed for a lab
  #checkov:skip=CKV_AWS_67:Multi-region is a variable; projects accounts block it, standard accounts set multi_region = true
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = var.log_bucket_name
  s3_key_prefix                 = "cloudtrail"
  kms_key_id                    = var.kms_key_arn
  is_multi_region_trail         = var.multi_region
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }
}
