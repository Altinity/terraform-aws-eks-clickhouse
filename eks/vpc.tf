# 🚨 This VPC module includes the creation of an Internet Gateway and public subnets, which simplifies cluster deployment and testing.
# IMPORTANT: For preprod and prod use cases, it is crucial to consult with your security team and AWS architects to design a private infrastructure solution that aligns with your security requirements.

# The VPC is configured with DNS support and hostnames,
# which are essential for EKS and other AWS services to operate correctly.
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.tags
}

# Creates a series of public subnets within the VPC based on the var.subnets input variable,
# which contains details like CIDR blocks and availability zones.
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

# Attaches an Internet Gateway (IGW) to the VPC,
# enabling communication between resources in the VPC and the internet.
# This is crucial for public subnets to allow inbound and outbound traffic to the internet.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = var.tags
}

# Defines a route table for the VPC that routes all outbound traffic (0.0.0.0/0) to the internet via the IGW.
# Each subnet in the VPC is associated with this route table
# (resources within these subnets can initiate outbound connections to the internet.)
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

# Creates a VPC endpoint for Amazon S3, enabling private connections
# between the VPC and S3 without requiring traffic to traverse the public internet.
# Enhances security and performance for AWS services that require S3 access.
resource "aws_vpc_endpoint" "this" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.this.id]
  tags              = var.tags
}
