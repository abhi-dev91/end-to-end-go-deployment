locals {
  name = "example"
  environment = "test"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
}

module "backend" {
  source                       = "squareops/tfstate/aws"
  logging                      = true
  bucket_name                  = format("%s-%s-%s", local.environment, local.name, "${lower(random_string.bucket_suffix.result)}") #unique global s3 bucket name
  environment                  = local.environment
  force_destroy                = true
  versioning_enabled           = true
  cloudwatch_logging_enabled   = false
  log_retention_in_days        = 90
  log_bucket_lifecycle_enabled = false
  s3_ia_retention_in_days      = 90
  s3_galcier_retention_in_days = 180
}