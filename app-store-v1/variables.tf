# Region us-east-1 is used as default, but you can change it to your preferred region. Just make sure to update the AMI ID accordingly, as AMI IDs are region-specific.
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Availability zones are used for creating subnets and distributing resources across multiple zones for high availability. The default values are for the us-east-1 region, but you can update them based on your chosen region. You can find the availability zones for your region in the AWS Management Console under EC2 > Availability Zones.
variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a","us-east-1b"]
}

# AMI ID is required for launching EC2 instances. The default value provided is for Ubuntu 20.04 LTS in the us-east-1 region. You can find the latest AMI for your region here: https://cloud-images.ubuntu.com/locator/ec2/. Make sure to update the AMI ID if you change the region.
variable "ami" {
  description = "AMI ID (must match region)"
  type        = string
}

# Bastion CIDR allowed SSH to bastion to private server
variable "bastion_cidr" {
  description = "CIDR allowed to SSH to bastion (use YOUR_IP/32)"
  type        = string
  default     = "0.0.0.0/0"
}

# Common tags for all resources, you can add more tags as needed. These tags will be merged with resource-specific tags in the modules.
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "StripeApp"
    Environment = "Dev"
    Owner       = "Anil"
  }
}
