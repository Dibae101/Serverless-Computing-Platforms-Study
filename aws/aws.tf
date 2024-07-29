provider "aws" {
  region = "us-west-2"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "kms_decrypt" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}

# Lambda Function
resource "aws_lambda_function" "test_lambda" {
  filename         = "lambda_function_payload.zip"
  function_name    = "test_lambda"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "index.handler"
  runtime          = "python3.8"

  environment {
    variables = {
      KMS_KEY_ID = aws_kms_key.lambda_key.id
    }
  }

  source_code_hash = filebase64sha256("lambda_function_payload.zip")

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.kms_decrypt,
  ]
}

# KMS Key for encryption
resource "aws_kms_key" "lambda_key" {
  description             = "KMS key for Lambda function"
  deletion_window_in_days = 10
}

# API Gateway
resource "aws_api_gateway_rest_api" "test_api" {
  name        = "test_api"
  description = "API Gateway for Lambda function"
}

resource "aws_api_gateway_resource" "test_resource" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  parent_id   = aws_api_gateway_rest_api.test_api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test_method" {
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  resource_id   = aws_api_gateway_resource.test_resource.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.test_api.id
  resource_id             = aws_api_gateway_resource.test_resource.id
  http_method             = aws_api_gateway_method.test_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.test_lambda.invoke_arn
}

# Cognito User Pool
resource "aws_cognito_user_pool" "test_user_pool" {
  name = "test_user_pool"
}

resource "aws_cognito_user_pool_client" "test_user_pool_client" {
  user_pool_id = aws_cognito_user_pool.test_user_pool.id
  name         = "test_user_pool_client"
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name          = "cognito_authorizer"
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  identity_source = "method.request.header.Authorization"
  type          = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.test_user_pool.arn]
}

# Deploy API
resource "aws_api_gateway_deployment" "test_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]

  rest_api_id = aws_api_gateway_rest_api.test_api.id
  stage_name  = "prod"
}

# CloudWatch Logging for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.test_lambda.function_name}"
  retention_in_days = 14
}

# CloudWatch Logging for API Gateway
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.test_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.test_api.id
  stage_name    = "prod"
}

resource "aws_cloudwatch_log_group" "api_gw_log_group" {
  name              = "/aws/apigateway/test_api"
  retention_in_days = 14
}

resource "aws_api_gateway_method_settings" "method_settings" {
  rest_api_id = aws_api_gateway_rest_api.test_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name

  method_path = "/*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
    data_trace_enabled = true
  }
}

# CloudTrail for API logging
resource "aws_cloudtrail" "test_trail" {
  name                          = "test_trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true
}

resource "aws_s3_bucket" "trail_bucket" {
  bucket = "cloudtrail-logs-bucket"

  lifecycle_rule {
    id      = "keep-30-days"
    enabled = true

    expiration {
      days = 30
    }
  }
}