# S3 bucket creations
resource "aws_s3_bucket" "bucket" {
    bucket = "my-terraform-lambda-bucket-aj"
}

# Uploading the Lambda function code to S3

resource "aws_s3_object" "lambda_zip" {
    bucket = aws_s3_bucket.bucket.id
    key    = "paython/lambda_function.zip"
    source = "paython/lambda_function.zip"
    etag = filemd5("paython/lambda_function.zip")
}

# IAM role for Lambda execution

resource "aws_iam_role" "lambda_role" {
    name = "lambda_execution_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Action = "sts:AssumeRole",
                Effect = "Allow",
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

# Attach AWSLambdaBasicExecutionRole policy to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda function
resource "aws_lambda_function" "my_lambda" {
    function_name = "my_lambda_function"
    s3_bucket     = aws_s3_bucket.bucket.id
    s3_key        = aws_s3_object.lambda_zip.key
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.8"
    role          = aws_iam_role.lambda_role.arn
    timeout       = 900
    memory_size   = 128
}

# Output the Lambda function ARN
output "lambda_function_arn" {
    value = aws_lambda_function.my_lambda.arn
}