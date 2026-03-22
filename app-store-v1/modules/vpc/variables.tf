# Availability zones for the VPC
variable "azs" {
  type = list(string)
}
# Tags for all resources in this module
variable "tags" {
  type = map(string)
}
