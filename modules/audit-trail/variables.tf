variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the S3 bucket that receives CloudTrail logs."
  type        = string
}

variable "multi_region" {
  description = "Record API calls in every region. Leave false on AWS 'projects' accounts."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt CloudTrail logs."
  type        = string
}

variable "cloudwatch_logs_enabled" {
  description = "Also stream the trail to an encrypted CloudWatch log group, so detections and alarms can watch it in near real time. Used by the aws-cloud-detection-lab repo."
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Days to keep CloudTrail events in CloudWatch Logs (the S3 archive keeps its own copy)."
  type        = number
  default     = 30
}
