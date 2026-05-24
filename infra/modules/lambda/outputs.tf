output "ocr_trigger_arn" {
  value = aws_lambda_function.ocr_trigger.arn
}

output "thumbnail_generator_arn" {
  value = aws_lambda_function.thumbnail_generator.arn
}

output "scheduled_cleanup_arn" {
  value = aws_lambda_function.scheduled_cleanup.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}
