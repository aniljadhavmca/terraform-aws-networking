resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = merge(var.tags, {
    Name = "main-vpc"
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "public-subnet"
  })
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = element(var.azs, count.index)
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "private-subnet"
  })
  cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index+2)
  availability_zone = element(var.azs, count.index)
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

output "vpc_id" { value = aws_vpc.main.id }
output "public_subnets" { value = aws_subnet.public[*].id }
output "private_subnets" { value = aws_subnet.private[*].id }