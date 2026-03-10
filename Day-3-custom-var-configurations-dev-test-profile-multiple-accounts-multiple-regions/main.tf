resource "aws_instance" "dev" {
    ami = var.ami_id
    instance_type = var.instance_type
    provider = aws.devenv
    tags = {
        Name = "dev-instance"
    }
}
resource "aws_instance" "test" {
    ami = var.test_ami_id
    instance_type = var.test_instance_type
    provider = aws.testenv
    tags = {
        Name = "test-instance"
    }
}