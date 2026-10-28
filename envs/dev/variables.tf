variable "region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-2"
}

variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "hlz"
}

variable "owner" {
  description = "Owner tag applied to every resource."
  type        = string
  default     = "shabangtech"
}

# Account capabilities. The defaults suit AWS's newer "projects" accounts
# (free plan). In a standard account or one with advanced features
# activated, set these to true in a terraform.tfvars file.

variable "enable_guardduty" {
  description = "Turn on GuardDuty threat detection."
  type        = bool
  default     = false
}

variable "enable_access_analyzer" {
  description = "Turn on IAM Access Analyzer."
  type        = bool
  default     = false
}

variable "multi_region_trail" {
  description = "Make the CloudTrail record every region."
  type        = bool
  default     = false
}

variable "cloudtrail_to_cloudwatch" {
  description = "Stream CloudTrail into CloudWatch Logs for real-time detections (needed by aws-cloud-detection-lab). Adds 3 resources."
  type        = bool
  default     = false
}
