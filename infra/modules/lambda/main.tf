data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── Shared Lambda IAM role ────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions" {
  name = "${var.name_prefix}-lambda-permissions"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
        ]
        Resource = [var.processing_queue_arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:HeadObject",
        ]
        Resource = [
          "${var.documents_bucket_arn}/*",
          "${var.thumbnails_bucket_arn}/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["textract:StartDocumentTextDetection", "textract:GetDocumentTextDetection"]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = [var.processing_jobs_table_arn]
      },
    ]
  })
}

# ── ocr-trigger — fires on S3 upload, pushes to processing SQS ───────────

resource "aws_cloudwatch_log_group" "ocr_trigger" {
  name              = "/aws/lambda/${var.name_prefix}-ocr-trigger"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "ocr_trigger" {
  function_name = "${var.name_prefix}-ocr-trigger"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30
  memory_size   = 128

  # Placeholder package — replaced by CI/CD after lambdas/ocr-trigger is built
  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = {
      PROCESSING_QUEUE_URL = var.processing_queue_url
      AWS_ACCOUNT_ID       = data.aws_caller_identity.current.account_id
    }
  }

  depends_on = [aws_cloudwatch_log_group.ocr_trigger]
}

resource "aws_lambda_permission" "ocr_trigger_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ocr_trigger.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.documents_bucket_arn
}

resource "aws_s3_bucket_notification" "documents_upload" {
  bucket = var.documents_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.ocr_trigger.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.ocr_trigger_s3]
}

# ── thumbnail-generator — triggered by SQS or S3 event ───────────────────

resource "aws_cloudwatch_log_group" "thumbnail_generator" {
  name              = "/aws/lambda/${var.name_prefix}-thumbnail-generator"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "thumbnail_generator" {
  function_name = "${var.name_prefix}-thumbnail-generator"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60
  memory_size   = 512 # PDF rendering needs more memory

  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = {
      DOCUMENTS_BUCKET   = var.documents_bucket_name
      THUMBNAILS_BUCKET  = var.thumbnails_bucket_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.thumbnail_generator]
}

# ── scheduled-cleanup — EventBridge cron, removes expired DynamoDB entries ──

resource "aws_cloudwatch_log_group" "scheduled_cleanup" {
  name              = "/aws/lambda/${var.name_prefix}-scheduled-cleanup"
  retention_in_days = var.log_retention_days
}

resource "aws_lambda_function" "scheduled_cleanup" {
  function_name = "${var.name_prefix}-scheduled-cleanup"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 300
  memory_size   = 128

  filename         = "${path.module}/placeholder.zip"
  source_code_hash = filebase64sha256("${path.module}/placeholder.zip")

  environment {
    variables = {
      PROCESSING_JOBS_TABLE = var.processing_jobs_table_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.scheduled_cleanup]
}

resource "aws_cloudwatch_event_rule" "cleanup_schedule" {
  name                = "${var.name_prefix}-cleanup-schedule"
  description         = "Trigger cleanup Lambda daily at 01:00 UTC"
  schedule_expression = "cron(0 1 * * ? *)"
}

resource "aws_cloudwatch_event_target" "cleanup_lambda" {
  rule      = aws_cloudwatch_event_rule.cleanup_schedule.name
  target_id = "ScheduledCleanup"
  arn       = aws_lambda_function.scheduled_cleanup.arn
}

resource "aws_lambda_permission" "eventbridge_cleanup" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cleanup_schedule.arn
}
