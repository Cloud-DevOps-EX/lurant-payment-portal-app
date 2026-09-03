resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-app"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_lambda_function" "app" {
  function_name = "${var.project_name}-${var.environment}-app"
  role          = aws_iam_role.lambda_exec.arn
  handler       = var.handler
  runtime       = var.runtime
  memory_size   = var.memory_size
  timeout       = var.timeout

  s3_bucket         = var.artifact_bucket_name
  s3_key            = var.artifact_s3_key
  s3_object_version = var.artifact_s3_object_version

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      DB_SECRET_ARN = var.db_secret_arn
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.lambda_inline,
    aws_iam_role_policy_attachment.vpc_access,
    aws_cloudwatch_log_group.lambda,
  ]
}
