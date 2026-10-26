# Dev environment: wires the modules together.

module "log_archive" {
  source = "../../modules/log-archive"

  name_prefix        = var.name_prefix
  log_retention_days = 90
}

module "network" {
  source = "../../modules/network"

  name_prefix         = var.name_prefix
  cidr_block          = "10.20.0.0/16"
  az_count            = 2
  flow_log_bucket_arn = module.log_archive.bucket_arn

  depends_on = [module.log_archive]
}

module "audit_trail" {
  source = "../../modules/audit-trail"

  name_prefix     = var.name_prefix
  log_bucket_name = module.log_archive.bucket_name
  kms_key_arn     = module.log_archive.kms_key_arn

  depends_on = [module.log_archive]
}

module "security_baseline" {
  source = "../../modules/security-baseline"

  name_prefix      = var.name_prefix
  enable_guardduty = var.enable_guardduty
}
