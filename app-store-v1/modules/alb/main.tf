# ALB module for the application load balancer, including security groups, target groups for frontend and backend, and listener rules for routing traffic based on path patterns.
# Security group for the ALB to allow incoming HTTP traffic and optionally HTTPS traffic. The security group is attached to the ALB to control access.
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id
  
  # Allow HTTP traffic from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic from anywhere (optional, can be removed if not using HTTPS)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Add tags for better resource management
  tags = merge(var.tags, { Name = "alb-sg" })
}

# Create the Application Load Balancer in the public subnets with the security group attached
resource "aws_lb" "alb" {
  name               = "stripe-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.alb_sg.id]
  tags               = merge(var.tags, { Name = "alb" })
}

# Frontend target group for the app running on port 80, with health checks configured to monitor the root path. The target group is associated with the VPC and tagged for identification. 
resource "aws_lb_target_group" "frontend" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = "/" }
  tags = merge(var.tags, { Name = "frontend-tg" })
}

# Backend target group for the API running on port 5000, with similar health check configuration. This target group is also associated with the VPC and tagged for identification.
resource "aws_lb_target_group" "backend" {
  name     = "backend-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check { path = "/" }
  tags = merge(var.tags, { Name = "backend-tg" })
}

# Listener for the ALB that listens on port 80 and forwards traffic to the frontend target group by default. The listener is associated with the ALB and configured with a default action to forward requests to the frontend target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Listener rule that routes requests with the path pattern "/api/*" to the backend target group. The rule is associated with the HTTP listener and has a priority of 1 to ensure it is evaluated before the default action. The condition checks for the specified path pattern and forwards matching requests to the backend target group.
resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern { values = ["/api/*"] }
  }
}

# Outputs to provide the ARNs of the frontend and backend target groups, the ID of the ALB security group, and the DNS name of the ALB for use in other modules or for reference after deployment.
output "frontend_tg" {
  value = aws_lb_target_group.frontend.arn
}

# Backedm target group ARN output for reference in other modules or for use in configuration of compute resources that will be registered with this target group.
output "backend_tg" {
  value = aws_lb_target_group.backend.arn
}

# ALB ARN output for reference in other modules or for use in configuration of compute resources that will be registered with this target group.
output "alb_sg" {
  value = aws_security_group.alb_sg.id
}

# ALB DNS name output to provide the DNS name of the ALB, which can be used for accessing the application after deployment or for reference in other modules that may need to know the ALB's endpoint.
output "alb_dns" {
  value = aws_lb.alb.dns_name
}
