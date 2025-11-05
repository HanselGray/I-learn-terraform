output "s3_bucket_name" {
  description = "Name of the bucket used for storing logs"
  value       = aws_s3_bucket.securityhub_log_bucket.id
}
  