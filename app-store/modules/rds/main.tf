resource "aws_db_subnet_group" "main" {
  subnet_ids = var.private_subnets
}

resource "aws_db_instance" "db" {
  engine = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20

  username = "admin"
  password = "Password123!"

  db_subnet_group_name = aws_db_subnet_group.main.name
  skip_final_snapshot  = true

  tags = merge(var.tags, {
    Name = "stripe-db"
  })
}