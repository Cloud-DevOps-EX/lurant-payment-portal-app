output "db_instance_id" {
  value = aws_db_instance.this.id
}

output "db_address" {
  value = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding host/port/username/password/dbname — this is what the Lambda IAM role is scoped to read."
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "kms_key_arn" {
  value = aws_kms_key.db.arn
}

