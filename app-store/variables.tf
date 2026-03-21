variable "region" {
  default = "us-east-1"
}

variable "ami" {
  description = "AMI ID"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)

  default = {
    Project     = "StripeApp"
    Environment = "Dev"
    Owner       = "Anil"
  }
}