variable "name_prefix" {
  description = "Short prefix used in resource names."
  type        = string
}

variable "cidr_block" {
  description = "CIDR range for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 3
    error_message = "az_count must be between 1 and 3."
  }
}

variable "flow_log_bucket_arn" {
  description = "ARN of the S3 bucket that receives VPC flow logs."
  type        = string
}
