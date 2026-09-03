data "aws_caller_identity" "current" {}

locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  tags         = local.tags
}

module "artifact_store" {
  source = "./modules/artifact_store"

  project_name = var.project_name
  environment  = var.environment
  account_id   = data.aws_caller_identity.current.account_id
  tags         = local.tags
}

module "database" {
  source = "./modules/database"

  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.network.private_subnet_ids
  db_security_group_id = module.network.db_security_group_id
  instance_class       = var.db_instance_class
  deletion_protection  = var.db_deletion_protection
  skip_final_snapshot  = var.db_skip_final_snapshot
  tags                 = local.tags
}

module "lambda_api" {
  source = "./modules/lambda_api"

  project_name               = var.project_name
  environment                = var.environment
  private_subnet_ids         = module.network.private_subnet_ids
  lambda_security_group_id   = module.network.lambda_security_group_id
  artifact_bucket_name       = module.artifact_store.bucket_name
  artifact_s3_key            = var.artifact_s3_key
  artifact_s3_object_version = var.artifact_s3_object_version
  db_secret_arn              = module.database.db_secret_arn
  db_secret_kms_key_arn      = module.database.kms_key_arn
  tags                       = local.tags
}
