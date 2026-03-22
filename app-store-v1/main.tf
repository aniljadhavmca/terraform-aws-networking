# Terraform configuration for App Store V1 infrastructure
provider "aws" {
  region = var.region
}

# Other providers (e.g., TLS for key generation, local for file output)
# TLS provider for generating SSH keys
provider "tls" {}

# Local provider for writing SSH keys to the filesystem
provider "local" {}

# VPC and networking Modules 

# VPC module with public and private subnets, IGW, NAT, and route tables
module "vpc" {
  source = "./modules/vpc"
  azs    = var.azs
  tags   = var.common_tags
}

# ALB module with security groups and target groups for frontend and backend
module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  tags           = var.common_tags
}

# Compute module for EC2 instances (bastion and app servers) with security groups and key management
module "compute" {
  source            = "./modules/compute"
  vpc_id            = module.vpc.vpc_id
  private_subnets   = module.vpc.private_subnets
  public_subnets    = module.vpc.public_subnets
  alb_sg            = module.alb.alb_sg
  frontend_tg       = module.alb.frontend_tg
  backend_tg        = module.alb.backend_tg
  ami               = var.ami
  bastion_cidr      = var.bastion_cidr
  tags              = var.common_tags
}

# RDS module for MySQL database with subnet groups, security groups, and instance configuration
module "rds" {
  source          = "./modules/rds"
  private_subnets = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  tags            = var.common_tags
}

# Outputs for key infrastructure details like ALB DNS, bastion host IP, and SSH key path
output "alb_dns" {
  value = module.alb.alb_dns
}

# Bastion host public IP for SSH access
output "bastion_public_ip" {
  value = module.compute.bastion_public_ip
}

# Path to the private key for SSH access to instances, useful for connecting to the bastion host and then to private instances
output "ssh_key_path" {
  value = module.compute.private_key_path
}
