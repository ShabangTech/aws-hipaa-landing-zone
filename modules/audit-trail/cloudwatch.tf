# Optional: stream the trail into CloudWatch Logs so detections (metric
# filters and alarms) can react within minutes instead of waiting on S3.
# Off by default. The aws-cloud-detection-lab repo turns it on.

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "trail" {
  #checkov:skip=CKV_AWS_338:Lab keeps 30 days in CloudWatch; the S3 archive is the long-term copy
  count = var.cloudwatch_logs_enabled ? 1 : 0

  name              = "/${var.name_prefix}/cloudtrail"
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = var.kms_key_arn
}

data "aws_iam_policy_document" "trail_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "trail_to_cloudwatch" {
  count = var.cloudwatch_logs_enabled ? 1 : 0

  name               = "${var.name_prefix}-trail-to-cloudwatch"
  assume_role_policy = data.aws_iam_policy_document.trail_assume.json
}

# Least privilege: write streams and events into this one log group only.
resource "aws_iam_role_policy" "trail_to_cloudwatch" {
  count = var.cloudwatch_logs_enabled ? 1 : 0

  name = "write-trail-log-group"
  role = aws_iam_role.trail_to_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.trail[0].arn}:log-stream:*"
    }]
  })
}
