variable "vpc_id" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "alb_sg" {}
variable "frontend_tg" {}
variable "backend_tg" {}
variable "ami" {}

variable "tags" {
  type = map(string)
}