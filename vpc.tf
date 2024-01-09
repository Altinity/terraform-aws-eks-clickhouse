resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nachos-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "nachos-gateway"
  }
}

locals {
  subnets = [
    { cidr_block = "10.0.1.0/24", az = "sa-east-1a" },
    { cidr_block = "10.0.2.0/24", az = "sa-east-1b" },
    { cidr_block = "10.0.3.0/24", az = "sa-east-1c" }
  ]
}

resource "aws_subnet" "this" {
  count                   = length(local.subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnets[count.index].cidr_block
  availability_zone       = local.subnets[count.index].az
  map_public_ip_on_launch = true

  tags = {
    Name = "nachos-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "nachos-root-table"
  }
}

resource "aws_route_table_association" "this" {
  count          = length(aws_subnet.this)
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this.id
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.this.id]

  tags = {
    Name = "nachos-s3-endpoint"
  }
}