output "state_bucket_name" {
  description = "S3 bucket name to use in infra/backend.tf."
  value       = aws_s3_bucket.tf_state.bucket
}

output "lock_table_name" {
  description = "DynamoDB table name to use in infra/backend.tf."
  value       = aws_dynamodb_table.tf_lock.name
}

output "github_actions_role_arn" {
  description = "IAM role ARN for the GitHub Actions workflow to assume via OIDC (role-to-assume input)."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN (created here, or the existing one that was reused)."
  value       = local.oidc_provider_arn
}
