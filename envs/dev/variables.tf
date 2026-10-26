variable "region" {
  description = "AWS region for this environment."
  type        = string
  default     = "us-east-1"
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

variable "enable_guardduty" {
  description = "Turn on GuardDuty threat detection."
  type        = bool
  default     = true
}
