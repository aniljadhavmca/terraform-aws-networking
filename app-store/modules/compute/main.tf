# Generate key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair
resource "aws_key_pair" "key" {
  key_name   = "stripe-key"
  public_key = tls_private_key.key.public_key_openssh
}

# Save private key locally
resource "local_file" "key" {
  content  = tls_private_key.key.private_key_pem
  filename = "${path.module}/stripe-key.pem"
  file_permission = "0400"
}

# Bastion SG
resource "aws_security_group" "bastion" {
  vpc_id = var.vpc_id

    tags = merge(var.tags, {
    Name = "bastion-sg"
  })

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # change this
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Private SG
resource "aws_security_group" "private" {
  vpc_id = var.vpc_id

  tags = merge(var.tags, {
    Name = "private-sg"
  })

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [var.alb_sg]
  }

  ingress {
    from_port = 5000
    to_port   = 5000
    protocol  = "tcp"
    security_groups = [var.alb_sg]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion EC2
resource "aws_instance" "bastion" {
  ami           = var.ami
  tags = merge(var.tags, {
    Name = "bastion-host"
  })
  instance_type = "t3.micro"
  subnet_id     = var.public_subnets[0]
  key_name      = aws_key_pair.key.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  associate_public_ip_address = true
}

# Launch Templates
resource "aws_launch_template" "frontend" {
  image_id = var.ami
  instance_type = "t3.micro"
  key_name = aws_key_pair.key.key_name

  network_interfaces {
    security_groups = [aws_security_group.private.id]
  }
}

resource "aws_launch_template" "backend" {
  image_id = var.ami
  instance_type = "t3.micro"
  key_name = aws_key_pair.key.key_name

  network_interfaces {
    security_groups = [aws_security_group.private.id]
  }
}

# Auto Scaling
resource "aws_autoscaling_group" "frontend" {
  desired_capacity = 2
  max_size = 4
  min_size = 2
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id = aws_launch_template.frontend.id
    version = "$Latest"
  }

  target_group_arns = [var.frontend_tg]

  tag {
    key                 = "Name"
    value               = "frontend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "StripeApp"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Dev"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "backend" {
  desired_capacity = 2
  max_size = 4
  min_size = 2
  vpc_zone_identifier = var.private_subnets

  launch_template {
    id = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [var.backend_tg]
  
  tag {
    key                 = "Name"
    value               = "backend"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "StripeApp"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "Dev"
    propagate_at_launch = true
  }
  
}