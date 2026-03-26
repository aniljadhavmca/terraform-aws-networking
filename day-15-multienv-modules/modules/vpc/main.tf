variable "cidr_block" {}
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
}
output "vpc_id" { value = aws_vpc.vpc.id }
