# Generate SSH key
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
resource "local_file" "private_key" {
  content  = tls_private_key.key.private_key_pem
  filename = "${path.module}/stripe-key.pem"
  file_permission = "0400"
}

# Bastion SG
resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id
  # Restrict SSH access to the bastion host to the specified CIDR block (e.g., your office IP or home IP). This enhances security by limiting who can access the bastion host.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_cidr]
  }
  # Allow all outbound traffic from the bastion host to enable it to connect to the private instances and other resources as needed. This is necessary for the bastion host to function properly as a jump server.
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
  # Allow incoming traffic on port 80 (HTTP) from the ALB security group. This allows the frontend instances to receive web traffic from the ALB.
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg]
  }
  # Allow incoming traffic on port 5000 (API) from the ALB security group. This allows the backend instances to receive API traffic from the ALB.
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [var.alb_sg]
  }
  # Allow incoming SSH traffic on port 22 from the bastion host security group. This allows you to SSH into the private instances through the bastion host for management and troubleshooting purposes.
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  # Allow all outbound traffic from the private instances to enable them to connect to the ALB, the internet (for updates and external API calls), and other resources as needed. This is necessary for the private instances to function properly and communicate with other components of the architecture.
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
  # Tag specifications for the backend launch template to ensure that instances launched from this template are tagged appropriately for identification and management. This includes merging common tags with a specific Name tag for the backend instances.
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
  desired_capacity          = 2 # Set the desired capacity to 2 to ensure that there are always 2 instances running in the backend Auto Scaling Group. This provides high availability and load distribution for the backend services.
  max_size                  = 2 # Set the maximum size to 2 to prevent the Auto Scaling Group from launching more than 2 instances. This helps control costs and ensures that the backend environment remains stable without scaling beyond the intended capacity.
  min_size                  = 2 # Set the minimum size to 2 to ensure that there are always at least 2 instances running in the backend Auto Scaling Group. This guarantees that the backend services are always available and can handle incoming traffic, even if one instance fails or is terminated for maintenance.
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
# Output the public IP address of the bastion host for reference after deployment. This allows users to easily identify the IP address they need to connect to when accessing the bastion host via SSH.
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
# Output the path to the private key file for SSH access to the bastion host and private instances. This allows users to easily locate the private key needed for authentication when connecting to the bastion host or private instances via SSH.
output "private_key_path" {
  value = local_file.private_key.filename
}
