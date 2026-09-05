output "api_endpoint" {
  description = "Hostname for the HTTP API's $default stage."
  value       = trimsuffix(replace(aws_apigatewayv2_stage.default.invoke_url, "https://", ""), "/")
}

output "function_name" {
  value = aws_lambda_function.app.function_name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "web_acl_arn" {
  value = aws_wafv2_web_acl.api.arn
}
