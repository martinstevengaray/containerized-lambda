output "function_url" {
  description = "Public HTTPS endpoint for the echo Lambda."
  value       = aws_lambda_function_url.echo.function_url
}

output "ecr_repository_url" {
  description = "ECR repository holding the Lambda container image."
  value       = aws_ecr_repository.echo.repository_url
}

output "image_uri" {
  description = "Image URI (tag) deployed to the Lambda."
  value       = local.image_uri
}
