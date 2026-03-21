resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  tags = merge(var.tags, {
    Name = "alb-sg"
  })

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  load_balancer_type = "application"
  subnets            = var.public_subnets
  tags = merge(var.tags, {
    Name = "stripe-alb"
  })
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "frontend" {
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
}

resource "aws_lb_target_group" "backend" {
  port = 5000
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check { path = "/" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.http.arn
  priority = 1

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern { values = ["/api/*"] }
  }
}

output "frontend_tg" { value = aws_lb_target_group.frontend.arn }
output "backend_tg" { value = aws_lb_target_group.backend.arn }
output "alb_sg" { value = aws_security_group.alb_sg.id }