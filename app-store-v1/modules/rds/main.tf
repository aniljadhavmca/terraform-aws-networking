resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnets
  tags       = merge(var.tags, { Name = "db-subnet-group" })
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "db-sg" })
}

resource "aws_db_instance" "db" {
  identifier             = "stripe-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = "Password123!"
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot    = true

  tags = merge(var.tags, { Name = "stripe-db" })
}
