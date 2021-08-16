locals  {
  lambda_filename = "../java/target/lambda-1.0-SNAPSHOT.jar"
}

resource "aws_lambda_function" "java_lambda" {
  runtime = "java11"
  filename = local.lambda_filename
  source_code_hash = base64sha256(local.lambda_filename)
  function_name = "java_lambda_function"
  handler = "org.tonberry.model.HandlerApiGateway"
  timeout = 60
  memory_size = 256
  role = aws_iam_role.lambda_exec.arn
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.java_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}