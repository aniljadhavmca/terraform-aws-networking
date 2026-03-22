# Generate SSH key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key" {
  key_name   = "stripe-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "private_key" {
  content  = tls_private_key.key.private_key_pem
  filename = "${path.module}/stripe-key.pem"
  file_permission = "0400"
}

# Bastion SG
resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "bastion-sg" })
}

# Private SG (from ALB + Bastion)
resource "aws_security_group" "private" {
  name   = "private-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg]
  }

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [var.alb_sg]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "private-sg" })
}

# Bastion host (public subnet)
resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnets[0]
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = merge(var.tags, { Name = "bastion" })
}

# Frontend Launch Template
resource "aws_launch_template" "frontend" {
  name_prefix   = "frontend-lt-"
  image_id      = var.ami
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key.key_name

  network_interfaces {
    security_groups = [aws_security_group.private.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "frontend" })
  }
}

# Backend Launch Template
resource "aws_launch_template" "backend" {
  name_prefix   = "backend-lt-"
  image_id      = var.ami
  instance_type = "t3.micro"
  key_name      = aws_key_pair.key.key_name

  network_interfaces {
    security_groups = [aws_security_group.private.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = "backend" })
  }
}

# Frontend ASG
resource "aws_autoscaling_group" "frontend" {
  name                      = "frontend-asg"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  vpc_zone_identifier       = var.private_subnets
  health_check_type         = "EC2"
  # health_check_grace_period = 600 # Recomanded
  health_check_grace_period = 7200 # Not recommanded 2 hours

  launch_template {
    id      = aws_launch_template.frontend.id
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
    value               = var.tags["Project"]
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.tags["Environment"]
    propagate_at_launch = true
  }

  # instance_refresh {
  #   strategy = "Rolling"
  #   preferences {
  #     min_healthy_percentage = 50
  #   }
  # }
}

# Backend ASG
resource "aws_autoscaling_group" "backend" {
  name                      = "backend-asg"
  desired_capacity          = 2
  max_size                  = 2
  min_size                  = 2
  vpc_zone_identifier       = var.private_subnets
  health_check_type         = "EC2"
  # health_check_grace_period = 600 # Recomanded
  health_check_grace_period = 7200 # Not recommanded 2 hours

  launch_template {
    id      = aws_launch_template.backend.id
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
    value               = var.tags["Project"]
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.tags["Environment"]
    propagate_at_launch = true
  }

  # instance_refresh {
  #   strategy = "Rolling"
  #   preferences {
  #     min_healthy_percentage = 50
  #   }
  # }
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "private_key_path" {
  value = local_file.private_key.filename
}
