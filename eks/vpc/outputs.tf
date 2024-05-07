output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID of newly created VPC"
}

output "subnets" {
  value       = var.enable_nat_gateway ? module.vpc.private_subnets : module.vpc.public_subnets
  description = "VPC subnets to create cluster on"
}
