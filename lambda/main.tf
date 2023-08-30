resource "null_resource" "lambda_build" {
  count = var.tf_build ? 1 : 0
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "CGO_ENABLED=0 GOARCH=amd64 GOOS=linux go build -tags lambda.norpc -o ${var.lambda_dir}/${var.buildname} ${var.lambda_dir}/*.go"
  }
}

data "archive_file" "this" {
  count       = var.tf_build ? 1 : 0
  depends_on  = [null_resource.lambda_build]
  source_file = "${var.lambda_dir}/${var.buildname}"
  output_path = "${var.lambda_dir}/main.zip"
  type        = "zip"
}

resource "aws_lambda_function" "this" {
  filename                       = var.tf_build ? data.archive_file.this[0].output_path : var.zip_package_filename
  source_code_hash               = var.tf_build ? data.archive_file.this[0].output_base64sha256 : sha256(filebase64(var.zip_package_filename))
  function_name                  = var.function_name
  description                    = var.description
  role                           = var.role_arn
  handler                        = var.handler
  runtime                        = var.runtime
  publish                        = var.publish
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.concurrency
  timeout                        = var.lambda_timeout
  tags                           = var.tags
  layers                         = var.layers

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config == null ? [] : [var.tracing_config]
    content {
      mode = tracing_config.value.mode
    }
  }

  dynamic "environment" {
    for_each = var.environment == null ? [] : [var.environment]
    content {
      variables = var.environment
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
      last_modified
    ]
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_lambda_function_event_invoke_config" "this" {
  function_name                = aws_lambda_function.this.function_name
  qualifier                    = aws_lambda_function.this.version
  maximum_event_age_in_seconds = var.event_age_in_seconds
  maximum_retry_attempts       = var.retry_attempts
}

resource "aws_lambda_function_event_invoke_config" "latest" {
  function_name                = aws_lambda_function.this.function_name
  qualifier                    = "$LATEST"
  maximum_event_age_in_seconds = var.event_age_in_seconds
  maximum_retry_attempts       = var.retry_attempts
}

# Cloud watch
resource "aws_cloudwatch_log_group" "this" {
  name              = format("/aws/lambda/%s", var.function_name)
  retention_in_days = var.log_retention

  tags = merge(var.tags,
    { Function = format("%s", var.function_name) }
  )
}

