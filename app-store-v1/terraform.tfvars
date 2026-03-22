# Update AMI for your region (example is us-east-1) 
# This is ubuntu 20.04 LTS, you can find the latest AMI for your region here: https://cloud-images.ubuntu.com/locator/ec2/
ami = "ami-0ec10929233384c7f" 

# IMPORTANT: restrict this to your IP, e.g. "49.36.x.x/32"
bastion_cidr = "0.0.0.0/0"
