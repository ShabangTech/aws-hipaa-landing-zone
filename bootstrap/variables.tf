variable "region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
  default     = "hlz"
}

variable "force_destroy" {
  description = "Allow terraform destroy to delete the bucket even if it holds state. Keep true for a lab, false for anything real."
  type        = bool
  default     = true
}
