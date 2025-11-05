data "aws_caller_identity" "current" {}

data "archive_file" "sort_findings" {
  type        = "zip"
  source_file = "${path.module}/lambda_source/lambda_sort_findings.py"
  output_path = "${path.module}/lambda_source/lambda_sort_findings.zip"
}