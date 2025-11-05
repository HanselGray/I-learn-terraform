# --- SecurityHub ---
resource "aws_cloudwatch_event_rule" "securityhub_cloudwatch_event" {
  depends_on = [aws_kinesis_firehose_delivery_stream.securityhub_firehose]

  description = "String"
  state       = "ENABLED"

  event_pattern = jsonencode({
  "detail-type" = ["Security Hub Findings - Imported"]
  "source"      = ["aws.securityhub"]
  "detail" = {
    "findings" = {
      "ProductArn" = [
        {
          "anything-but" = {
            "suffix" = "/aws/inspector"
          }
        }
      ]
      "Compliance" = {
        Status = ["FAILED", "WARNING"]
      }
      "Severity" = {
        "Label" = ["CRITICAL", "HIGH", "MEDIUM"]
      }
    }
  }
})

}

resource "aws_cloudwatch_event_target" "securityhub_event_target" {
  rule      = aws_cloudwatch_event_rule.securityhub_cloudwatch_event.name
  arn       = aws_kinesis_firehose_delivery_stream.securityhub_firehose.arn
  role_arn  = aws_iam_role.security_hub_delivery_role.arn
  target_id = "FirehoseStream"
}

resource "aws_iam_role" "security_hub_delivery_role" {
  name = "SecurityHubDeliveryRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecurityHubLogDelivery"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "securityhub_log_delivery_policy" {
  name = "SecurityHubFirehoseDeliveryPolicy"
  role = aws_iam_role.security_hub_delivery_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.securityhub_firehose.arn
        ]
      }
    ]
  })
}



# --- Kinesis Firehose Stream --- 
resource "aws_kinesis_firehose_delivery_stream" "securityhub_firehose" {
  depends_on = [
    aws_iam_role_policy.securityhub_firehose_delivery_policy,
    aws_s3_bucket.securityhub_log_bucket
  ]
  destination          = "extended_s3"

  name                 = "securityhub-firehose"
  
  extended_s3_configuration {
    bucket_arn         = aws_s3_bucket.securityhub_log_bucket.arn
    role_arn           = aws_iam_role.firehose_delivery_role.arn
    compression_format  = "UNCOMPRESSED"
    prefix              = "raw/firehose/"
    buffering_interval = 900
    buffering_size     = 128
  }
}

resource "aws_iam_role" "firehose_delivery_role" {
  name = "FirehoseDeliveryRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFirehoseDelivery"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "securityhub_firehose_delivery_policy" {
  name = "firehose_delivery_policy"
  role = aws_iam_role.firehose_delivery_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.securityhub_log_bucket.arn,
          "${aws_s3_bucket.securityhub_log_bucket.arn}/*"
        ]
      }
    ]
  })
}

