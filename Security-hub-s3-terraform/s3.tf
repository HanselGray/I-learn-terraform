resource "aws_s3_bucket" "securityhub_log_bucket" {
  depends_on = [
    aws_lambda_permission.allow_s3_invoke,
    aws_lambda_function.lambda_sort_findings
  ]
  bucket_prefix = "securityhub-log-"
}



# --- Life cycle configuration --- 
resource "aws_s3_bucket_lifecycle_configuration" "delete_raw_files" {
  bucket = aws_s3_bucket.securityhub_log_bucket.id

  rule {
    id     = "DeleteRawFiles"
    status = "Enabled"

    filter {
      prefix = "raw/"
    }

    expiration {
      days = 5
    }
  }
}



# --- Notification configuration ---
resource "aws_s3_bucket_notification" "lambda_notification" {
  bucket = aws_s3_bucket.securityhub_log_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_sort_findings.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/firehose/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}


# --- Permission for S3 to invoke Lambda ---
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sort_findings.function_name
  principal     = "s3.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}


