variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

# variable "aws_profile" {
#   type        = string
#   description = "AWS profile"
# }

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name"
  default     = "pojlkasndfj-1982030"
}

provider "aws" {
  region  = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
    }
  }
}
  

resource "aws_apigatewayv2_api" "aws-api-gateway-l3xiygho" {
    name          = "pok-gateway"
    protocol_type = "HTTP"
}

resource "aws_cloudwatch_log_group" "aws-api-gateway-l3xiygho-log-group" {
    name              = "/aws/apigateway/aws-api-gateway-l3xiygho"
    retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "aws-api-gateway-l3xiygho-stage" {
    api_id      = aws_apigatewayv2_api.aws-api-gateway-l3xiygho.id
    name        = "dev"
    auto_deploy = true
    
    access_log_settings {
        destination_arn = aws_cloudwatch_log_group.aws-api-gateway-l3xiygho-log-group.arn
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

output "stage_endpoint" {
    value = aws_apigatewayv2_stage.aws-api-gateway-l3xiygho-stage.invoke_url
}

resource "aws_apigatewayv2_integration" "aws-api-gateway-l3xiygho-to-aws-lambda-masxovpv-integration" {
    api_id           = aws_apigatewayv2_api.aws-api-gateway-l3xiygho.id
    integration_type = "AWS_PROXY"
    integration_uri  = aws_lambda_function.aws-lambda-masxovpv.invoke_arn
}

resource "aws_apigatewayv2_route" "aws-api-gateway-l3xiygho-to-aws-lambda-masxovpv-route" {
    api_id    = aws_apigatewayv2_api.aws-api-gateway-l3xiygho.id
    route_key = "GET /"
    target    = "integrations/${aws_apigatewayv2_integration.aws-api-gateway-l3xiygho-to-aws-lambda-masxovpv-integration.id}"
}
    
resource "aws_lambda_permission" "aws-api-gateway-l3xiygho-to-aws-lambda-masxovpv-permission" {
    statement_id  = "aws-api-gateway-l3xiygho-to-aws-lambda-masxovpv-permission"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.aws-lambda-masxovpv.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_apigatewayv2_api.aws-api-gateway-l3xiygho.execution_arn}/*/*"
}


data "archive_file" "aws-lambda-masxovpv-archive" {
    type        = "zip"
    source_dir  = "../src"
    output_path = ".output/aws-lambda-masxovpv-code.zip"
}


resource "aws_cloudwatch_log_group" "aws-lambda-masxovpv-log-group" {
    name              = "/aws/lambda/aws-lambda-masxovpv"
    retention_in_days = 7
}


resource "aws_iam_role" "aws-lambda-masxovpv-role" {
    name = "aws-lambda-masxovpv-role"

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


resource "aws_iam_role_policy_attachment" "aws-lambda-masxovpv-policy-attachment" {
    role       = aws_iam_role.aws-lambda-masxovpv-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "aws-lambda-masxovpv" {
    function_name    = "aws-lambda-masxovpv"
    role             = aws_iam_role.aws-lambda-masxovpv-role.arn
    handler          = "index.handler"
    runtime          = "nodejs20.x"
    timeout          = 30
    memory_size      = 128
    filename         = data.archive_file.aws-lambda-masxovpv-archive.output_path
    source_code_hash = data.archive_file.aws-lambda-masxovpv-archive.output_base64sha256
    logging_config {
        log_group  = aws_cloudwatch_log_group.aws-lambda-masxovpv-log-group.name
        log_format = "JSON"
    }

    environment {
        variables = {}
    }
}
