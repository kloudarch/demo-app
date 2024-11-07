variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "hello-world-5963881"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}


resource "aws_apigatewayv2_api" "aws-api-gateway-1" {
  name          = "api-gateway"
  protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "aws-api-gateway-1-log-group" {
  name              = "/aws/apigateway/aws-api-gateway-1"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "aws-api-gateway-1-stage" {
  api_id      = aws_apigatewayv2_api.aws-api-gateway-1.id
  name        = "dev"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.aws-api-gateway-1-log-group.arn
    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
    })
  }
}

resource "aws_apigatewayv2_integration" "aws-api-gateway-1-to-aws-lambda-4-integration" {
  api_id           = aws_apigatewayv2_api.aws-api-gateway-1.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.aws-lambda-4.invoke_arn
}

resource "aws_apigatewayv2_route" "aws-api-gateway-1-to-aws-lambda-4-route" {
  api_id    = aws_apigatewayv2_api.aws-api-gateway-1.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.aws-api-gateway-1-to-aws-lambda-4-integration.id}"
}

resource "aws_lambda_permission" "aws-api-gateway-1-to-aws-lambda-4-permission" {
  statement_id  = "aws-api-gateway-1-to-aws-lambda-4-permission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.aws-lambda-4.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.aws-api-gateway-1.execution_arn}/*/*"
}


data "archive_file" "aws-lambda-4-archive" {
  type        = "zip"
  source_dir  = "../"
  output_path = ".output/aws-lambda-4-code.zip"
}


resource "aws_cloudwatch_log_group" "aws-lambda-4-log-group" {
  name              = "/aws/lambda/aws-lambda-4"
  retention_in_days = 7
}


resource "aws_iam_role" "aws-lambda-4-role" {
  name = "aws-lambda-4-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_role_policy_attachment" "aws-lambda-4-policy-attachment" {
  role       = aws_iam_role.aws-lambda-4-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "aws-lambda-4" {
  function_name    = "aws-lambda-4"
  role             = aws_iam_role.aws-lambda-4-role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.aws-lambda-4-archive.output_path
  source_code_hash = data.archive_file.aws-lambda-4-archive.output_base64sha256
  logging_config {
    log_group  = aws_cloudwatch_log_group.aws-lambda-4-log-group.name
    log_format = "JSON"
  }

  environment {
    variables = {}
  }
}
