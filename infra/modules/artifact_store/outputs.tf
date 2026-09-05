output "bucket_name" {
  value = aws_s3_bucket.lambda_artifacts.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.lambda_artifacts.arn
}

