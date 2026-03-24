resource "aws_iam_policy" "s3_access_policy" {
  name        = "s3-access-policy"
  description = "Allow EC2 to access S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      }
    ]
  })
}

# create an IAM role for EC2 to assume
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# attach the S3 access policy to the EC2 role
resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
  depends_on = [ aws_iam_policy.s3_access_policy ]
}

# creating profile for EC2 to use the role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}

resource "aws_instance" "name" {
  instance_type = "t2.micro"
  ami           = "ami-0c2b8ca1dad447f8a"
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

}

resource "aws_s3_bucket" "name" {
  bucket = "my-unique-bucket-name-12345hwvdhwv"
  depends_on = [ aws_instance.name ]

  #dependency block is used to explicitly specify the order of resource creation. In this case, it ensures that the EC2 instance is created before the S3 bucket. This is important because the EC2 instance needs to assume the IAM role that has permissions to access the S3 bucket. By using depends_on, we can avoid potential issues where the S3 bucket is created before the EC2 instance, which could lead to permission errors when the EC2 instance tries to access the bucket.
#so here after create the EC2 instance, it will create the S3 bucket. This way, we ensure that the necessary IAM role and permissions are in place before the S3 bucket is created, allowing for proper access control and functionality.
}