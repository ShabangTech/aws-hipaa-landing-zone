variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "log_retention_days" {
  description = "Days to keep log objects before they expire."
  type        = number
  default     = 365
}

variable "kms_deletion_window_days" {
  description = "Waiting period before the KMS key is deleted after destroy (7-30)."
  type        = number
  default     = 7
}

variable "force_destroy" {
  description = "Allow terraform destroy to empty and delete the bucket. Keep true for a lab."
  type        = bool
  default     = true
}
