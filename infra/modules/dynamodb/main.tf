# ── ProcessingJobs — tracks OCR/classification pipeline state ─────────────

resource "aws_dynamodb_table" "processing_jobs" {
  name         = "${var.name_prefix}-ProcessingJobs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S" # DOC#<documentId>
  }

  attribute {
    name = "SK"
    type = "S" # JOB#<timestamp>
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  tags = { Name = "${var.name_prefix}-ProcessingJobs" }
}

# ── NotificationLog — in-app notifications per user ───────────────────────

resource "aws_dynamodb_table" "notification_log" {
  name         = "${var.name_prefix}-NotificationLog"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S" # USER#<userId>
  }

  attribute {
    name = "SK"
    type = "S" # NOTIF#<timestamp>
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = var.enable_pitr
  }

  tags = { Name = "${var.name_prefix}-NotificationLog" }
}

# ── UserSessions — optional; Cognito can own sessions instead ────────────

resource "aws_dynamodb_table" "user_sessions" {
  name         = "${var.name_prefix}-UserSessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"

  attribute {
    name = "PK"
    type = "S" # SESSION#<sessionId>
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = { Name = "${var.name_prefix}-UserSessions" }
}
