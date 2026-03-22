variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a","us-east-1b"]
}

variable "ami" {
  description = "AMI ID (must match region)"
  type        = string
}

variable "bastion_cidr" {
  description = "CIDR allowed to SSH to bastion (use YOUR_IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "StripeApp"
    Environment = "Dev"
    Owner       = "Anil"
  }
}
