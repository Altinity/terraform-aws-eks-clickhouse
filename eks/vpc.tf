# 🚨 This VPC module includes the creation of an Internet Gateway and public subnets, which simplifies cluster deployment and testing.
# IMPORTANT: For preprod and prod use cases, it is crucial to consult with your security team and AWS architects to design a private infrastructure solution that aligns with your security requirements.

locals {
  cidr_blocks    = [for subnet in var.subnets : subnet.cidr_block]
  azs            = [for subnet in var.subnets : subnet.az]
  public_subnets = module.vpc.public_subnets
}

# The VPC is configured with DNS support and hostnames,
# which are essential for EKS and other AWS services to operate correctly.
# ---
# Creates a series of public subnets within the VPC based on the var.subnets input variable,
# which contains details like CIDR blocks and availability zones.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.cluster_name}-vpc"
  cidr = var.cidr
  azs  = local.azs

  # ⚠️ Subnets are public, this means that eks control plane will be accesible over the internet
  # You can enable IP restrictions at eks cluser level setting the variable `public_access_cidrs`
  public_subnets          = local.cidr_blocks
  map_public_ip_on_launch = true

  # # This is crucial for public subnets to allow inbound and outbound traffic to the internet.
  enable_vpn_gateway = true

  tags = var.tags
}

# # Creates a VPC endpoint for Amazon S3, enabling private connections
# # between the VPC and S3 without requiring traffic to traverse the public internet.
# # Enhances security and performance for AWS services that require S3 access.
# resource "aws_vpc_endpoint" "this" {
#   vpc_id            = aws_vpc.this.id
#   service_name      = "com.amazonaws.${var.region}.s3"
#   vpc_endpoint_type = "Gateway"
#   route_table_ids   = [aws_route_table.this.id]

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.cluster_name}-s3-endpoint"
#     }
#   )
# }
