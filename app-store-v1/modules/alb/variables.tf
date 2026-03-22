# VPC ID where the ALB will be deployed
variable "vpc_id" {
  type = string
}
# Public subnets for the ALB
variable "public_subnets" {
  type = list(string)
}
# Tags for all resources in this module
variable "tags" {
  type = map(string)
}
