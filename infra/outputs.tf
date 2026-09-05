
output "lambda_function_name" {
  value = module.lambda_api.function_name
}

output "artifact_bucket_name" {
  description = "CI uploads the Lambda deployment zip here before terraform apply."
  value       = module.artifact_store.bucket_name
}

output "db_address" {
  value = module.database.db_address
}

output "db_secret_arn" {
  value = module.database.db_secret_arn
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "api_endpoint" {
  value = module.lambda_api.api_endpoint
}