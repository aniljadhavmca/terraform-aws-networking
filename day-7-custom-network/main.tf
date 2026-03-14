# Create VPC Prod on east 1 region 
resource "aws_vpc" "prod" { 
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod"
  }
}

# Create public subnet for prod VPC
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "public"
  }
  # IP range for public subnet
  cidr_block = "10.0.1.0/24"
  # Specify availability zone for the subnet
  availability_zone = "us-east-1a"
  # Assign public IP address to instances launched in this subnet
  map_public_ip_on_launch = true
}

# Create private subnet for prod VPC
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "private"
  }
  # IP range for private subnet
  cidr_block = "10.0.2.0/24"
  # Specify availability zone for the subnet
  availability_zone = "us-east-1a"
}

# Create Internet Gateway for the VPC
resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "prod-gw"
  }
}

# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  # No 'vpc' attribute needed
}

# Create NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

# Create route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "public-rt"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }
}

# Create route table for private subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "private-rt"
  }

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Associate public route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Associate private route table with private subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create Security group for prod VPC
resource "aws_security_group" "prod-sg" {
  name        = "prod-sg"
  description = "Security group for prod VPC"
  vpc_id      = aws_vpc.prod.id

  # Inbound rules to allow SSH and HTTP access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an SSH key pair
resource "aws_key_pair" "my_key" {
  key_name   = "my-key"
    public_key = file("/Users/anil.jadhav/Desktop/DevOps/Terrafoem-Practice/my-key.pub")# Updated path to your public key file
}

# Create EC2 instance in public subnet (bastion host)
resource "aws_instance" "bastion" {
  ami                    = "ami-02dfbd4ff395f2a1b" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids  = [aws_security_group.prod-sg.id]
  key_name               = aws_key_pair.my_key.key_name # Attach the key pair
  tags = {
    Name = "bastion"
  }
}

# Create EC2 instance in private subnet (app host)
resource "aws_instance" "app" {
  ami                    = "ami-02dfbd4ff395f2a1b" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids  = [aws_security_group.prod-sg.id]
  key_name               = aws_key_pair.my_key.key_name # Attach the key pair
  tags = {
    Name = "app"
  }
}
