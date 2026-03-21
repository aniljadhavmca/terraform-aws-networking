provider "aws" {
  region = var.region
}
provider "tls" {}

provider "local" {}

module "vpc" {
  source = "./modules/vpc"
  azs    = ["us-east-1a","us-east-1b"]
  tags   = var.common_tags
}

module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  tags           = var.common_tags
}

module "compute" {
  source            = "./modules/compute"

  vpc_id            = module.vpc.vpc_id
  private_subnets   = module.vpc.private_subnets
  public_subnets    = module.vpc.public_subnets

  alb_sg            = module.alb.alb_sg
  frontend_tg       = module.alb.frontend_tg
  backend_tg        = module.alb.backend_tg
  ami               = var.ami
  tags              = var.common_tags  
}

module "rds" {
  source          = "./modules/rds"
  private_subnets = module.vpc.private_subnets
 tags            = var.common_tags
}