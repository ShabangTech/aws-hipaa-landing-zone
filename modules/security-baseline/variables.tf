variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "enable_guardduty" {
  description = "Turn on GuardDuty threat detection (30-day free trial, then paid). Not available on AWS 'projects' accounts without advanced features."
  type        = bool
  default     = false
}

variable "enable_access_analyzer" {
  description = "Turn on IAM Access Analyzer. Not available on AWS 'projects' accounts without advanced features."
  type        = bool
  default     = false
}

variable "enable_password_policy" {
  description = "Set the IAM account password policy. Only useful where IAM users can sign in to the console."
  type        = bool
  default     = false
}
