## dev environment variables##
variable "ami_id" {
  description = "passing values to ami_id"
  default = ""
  type = string
}

variable "instance_type" {
  description = "passing values to instance_type"
  default = ""
  type = string
}

### test env variables## 
variable "test_ami_id" {
    description = "passing values to ami_id"
    default = ""
    type = string
  
}
variable "test_instance_type" {
    description = "passing values to instance_type"
    default = ""
    type = string
}

