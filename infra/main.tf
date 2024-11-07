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
  default     = "my-project12321-2565909"
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

output "stage_endpoint" {
    value = aws_apigatewayv2_stage.aws-api-gateway-1-stage.invoke_url
}

resource "aws_apigatewayv2_integration" "aws-api-gateway-1-to-aws-lambda-4-integration" {
    api_id           = aws_apigatewayv2_api.aws-api-gateway-1.id
    integration_type = "AWS_PROXY"
    integration_uri  = aws_lambda_function.aws-lambda-4.invoke_arn
}

resource "aws_apigatewayv2_route" "aws-api-gateway-1-to-aws-lambda-4-route" {
    api_id    = aws_apigatewayv2_api.aws-api-gateway-1.id
    route_key = "POST /"
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
    source_dir  = "../build"
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


resource "aws_sqs_queue" "aws-sqs-98zp5374" {
    name = "aws-sqs-98zp5374"
    delay_seconds = 0
    max_message_size = 262144
    message_retention_seconds = 60
    receive_wait_time_seconds = 0
    visibility_timeout_seconds = 30
    sqs_managed_sse_enabled = true
}


resource "aws_iam_policy" "aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-policy" {
  name = "aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.aws-sqs-98zp5374.arn
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-attachment" {
  name       = "aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-policy-attachment"
  policy_arn = aws_iam_policy.aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-policy.arn
  roles      = [aws_iam_role.aws-lambda-jgzv3pbt-role.name]
}

resource "aws_lambda_event_source_mapping" "aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-mapping" {
    event_source_arn = aws_sqs_queue.aws-sqs-98zp5374.arn
    function_name    = aws_lambda_function.aws-lambda-jgzv3pbt.function_name
    batch_size       = 1
    enabled          = true

    depends_on = [aws_sqs_queue.aws-sqs-98zp5374, aws_iam_role.aws-lambda-jgzv3pbt-role, aws_iam_policy.aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-policy, aws_iam_policy_attachment.aws-sqs-98zp5374-to-aws-lambda-jgzv3pbt-attachment]
}


resource "aws_iam_policy" "aws-lambda-4-to-aws-sqs-98zp5374-policy" {
  name        = "aws-lambda-4-to-aws-sqs-98zp5374-policy"
  description = "Policy for aws-lambda-4-to-aws-sqs-98zp5374"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            "sqs:SendMessage",
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.aws-sqs-98zp5374.arn
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "aws-lambda-4-to-aws-sqs-98zp5374-attachment" {
  name       = "aws-lambda-4-to-aws-sqs-98zp5374-policy-attachment"
  roles      = [aws_iam_role.aws-lambda-4-role.name]
  policy_arn = aws_iam_policy.aws-lambda-4-to-aws-sqs-98zp5374-policy.arn
}


data "archive_file" "aws-lambda-jgzv3pbt-archive" {
    type        = "zip"
    source_dir  = "../build"
    output_path = ".output/aws-lambda-jgzv3pbt-code.zip"
}


resource "aws_cloudwatch_log_group" "aws-lambda-jgzv3pbt-log-group" {
    name              = "/aws/lambda/aws-lambda-jgzv3pbt"
    retention_in_days = 7
}


resource "aws_iam_role" "aws-lambda-jgzv3pbt-role" {
    name = "aws-lambda-jgzv3pbt-role"

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


resource "aws_iam_role_policy_attachment" "aws-lambda-jgzv3pbt-policy-attachment" {
    role       = aws_iam_role.aws-lambda-jgzv3pbt-role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_lambda_function" "aws-lambda-jgzv3pbt" {
    function_name    = "aws-lambda-jgzv3pbt"
    role             = aws_iam_role.aws-lambda-jgzv3pbt-role.arn
    handler          = "index.handler"
    runtime          = "nodejs20.x"
    timeout          = 30
    memory_size      = 128
    filename         = data.archive_file.aws-lambda-jgzv3pbt-archive.output_path
    source_code_hash = data.archive_file.aws-lambda-jgzv3pbt-archive.output_base64sha256
    logging_config {
        log_group  = aws_cloudwatch_log_group.aws-lambda-jgzv3pbt-log-group.name
        log_format = "JSON"
    }

    environment {
        variables = {}
    }
}


resource "aws_s3_bucket" "aws-s3-j27lrtaj" {
    bucket = "s3-bucket"
}

resource "aws_s3_bucket_public_access_block" "aws-s3-j27lrtaj-block" {
    bucket                  = aws_s3_bucket.aws-s3-j27lrtaj.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "aws-s3-j27lrtaj-versioning" {
    bucket = aws_s3_bucket.aws-s3-j27lrtaj.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_iam_policy" "aws-lambda-jgzv3pbt-to-aws-s3-j27lrtaj-policy" {
  name        = "aws-lambda-jgzv3pbt-to-aws-s3-j27lrtaj-policy"
  path        = "/"
  description = "Policy for aws-lambda-jgzv3pbt-to-aws-s3-j27lrtaj"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
            
            
            "s3:GetObject","s3:ListObject","s3:GetObjectVersion","s3:PutObject","s3:DeleteObject"
            
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.aws-s3-j27lrtaj.arn}/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws-lambda-jgzv3pbt-to-aws-s3-j27lrtaj-attachment" {
  role       = aws_iam_role.aws-lambda-jgzv3pbt-role.name
  policy_arn = aws_iam_policy.aws-lambda-jgzv3pbt-to-aws-s3-j27lrtaj-policy.arn
}
