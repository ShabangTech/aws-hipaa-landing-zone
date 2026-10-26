variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "enable_guardduty" {
  description = "Turn on GuardDuty threat detection (30-day free trial, then paid)."
  type        = bool
  default     = true
}
