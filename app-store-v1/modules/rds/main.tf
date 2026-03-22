# RDS module for Stripe App Store
resource "aws_db_subnet_group" "main" {
  name       = "db-subnet-group"
  subnet_ids = var.private_subnets
  tags       = merge(var.tags, { Name = "db-subnet-group" })
}
# Security group for RDS allowing MySQL access from the VPC CIDR block and allowing all outbound traffic. This security group is associated with the RDS instance to control inbound and outbound traffic to the database, ensuring that only authorized traffic can access the database while allowing necessary outbound communication.
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

# RDS instance with MySQL engine, using the db.t3.micro instance class, 20 GB of allocated storage, and credentials for the admin user. The instance is associated with the previously created DB subnet group and security group, and is configured to skip the final snapshot on deletion for easier cleanup during development. The RDS instance is tagged for identification and management purposes.
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
