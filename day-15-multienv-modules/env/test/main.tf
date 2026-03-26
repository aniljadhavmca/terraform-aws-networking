variable "region" {}
variable "env" {}
variable "vpc_cidr" {}
variable "instance_type" {}
variable "ami" {}

provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"
  cidr_block = var.vpc_cidr
}

module "keypair" {
  source = "../../modules/keypair"
}

resource "aws_subnet" "public" {
  vpc_id = module.vpc.vpc_id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = true
}

module "ec2" {
  source = "../../modules/ec2"
  ami = var.ami
  instance_type = var.instance_type
  subnet_id = aws_subnet.public.id
  key_name = module.keypair.key_name
}
