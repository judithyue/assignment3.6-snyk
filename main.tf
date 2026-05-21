terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-1"
}

# package the python script into a zip file
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "ju-snyk-scan-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# basic execution policy for CloudWatch logging
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Provision the Lambda Function
resource "aws_lambda_function" "hello_world" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "ju-hello-world-snyk-demo"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda.handler"
  runtime          = "python3.11"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}