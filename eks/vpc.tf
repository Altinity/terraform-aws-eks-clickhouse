#---------------------------------------------------------------
# VPC and Subnets
#---------------------------------------------------------------
# WARNING: This VPC module includes the creation of an Internet Gateway and public subnets, which simplifies cluster deployment and testing.
# IMPORTANT: For preprod and prod use cases, it is crucial to consult with your security team and AWS architects to design a private infrastructure solution that aligns with your security requirements

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.tags
}

resource "aws_subnet" "this" {
  count             = length(var.subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.subnets[count.index].cidr_block
  availability_zone = var.subnets[count.index].az
  tags              = var.tags

  # ⚠️ Subnets are public, this means that eks control plane will be accesible over the internet
  # You can enable IP restrictions at eks cluser level setting the variable `public_access_cidrs`
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = var.tags
}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = var.tags
}

resource "aws_route_table_association" "this" {
  count          = length(aws_subnet.this)
  subnet_id      = aws_subnet.this[count.index].id
  route_table_id = aws_route_table.this.id
}

# This endpoint enables private connections between the VPC and S3
resource "aws_vpc_endpoint" "this" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.this.id]
  tags              = var.tags
}
