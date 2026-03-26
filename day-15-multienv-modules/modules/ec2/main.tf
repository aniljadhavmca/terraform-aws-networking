variable "ami" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "key_name" {}

resource "aws_instance" "app" {
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  key_name      = var.key_name

  instance_market_options {
    market_type = "spot"
  }
}
