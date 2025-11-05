resource "aws_lambda_function" "lambda_sort_findings" {
  filename         = data.archive_file.sort_findings.output_path    
  function_name    = "lambda_sort_findings"
  role             = aws_iam_role.lambda_sort_role.arn
  handler          = "lambda_sort_findings.handler"
  runtime          = "python3.12"
  description      = "Function sorts findings by AWS account id/product/region"
  memory_size      = 128
  timeout          = 300
  source_code_hash = data.archive_file.sort_findings.output_base64sha256
}

# --- Lambda role ---

resource "aws_iam_role" "lambda_sort_role" {
  name = "LambdaSortRole"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = ["lambda.amazonaws.com"]
        }
        Action = ["sts:AssumeRole"]
      }
    ]
  })
}

# --- Lambda role policies ---
resource "aws_iam_role_policy_attachment" "lambda_execute" {
  role       = aws_iam_role.lambda_sort_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}