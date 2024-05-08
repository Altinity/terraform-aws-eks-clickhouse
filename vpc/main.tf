# 🚨 This VPC module includes the creation of an Internet Gateway and public subnets, which simplifies cluster deployment and testing.
# IMPORTANT: For preprod and prod use cases, it is crucial to consult with your security team and AWS architects to design a private infrastructure solution that aligns with your security requirements.

# The VPC is configured with DNS support and hostnames,
# which are essential for EKS and other AWS services to operate correctly.
# ---
# Creates a series of public subnets within the VPC based on the var.subnets input variable,
# which contains details like CIDR blocks and availability zones.
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.cidr
  azs  = var.availability_zones

  public_subnets = var.public_cidr
  # ⚠️ If NAT gateway is disabled, your EKS nodes will automatically run under public subnets.
  private_subnets = var.enable_nat_gateway ? var.private_cidr : []

  map_public_ip_on_launch = !var.enable_nat_gateway
  enable_vpn_gateway      = !var.enable_nat_gateway
  enable_nat_gateway      = var.enable_nat_gateway
  single_nat_gateway      = true

  tags = var.tags
}
