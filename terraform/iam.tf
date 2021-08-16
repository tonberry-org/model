data "aws_iam_policy_document" "lambda_exec" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_exec.json
}

resource "aws_iam_role_policy_attachment" "aws_iam_role_policy_attachment" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}