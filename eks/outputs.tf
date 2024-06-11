output "cluster_node_pools" {
  value = local.node_pool_combinations
}

output "cluster_arn" {
  value       = module.eks.cluster_arn
  description = "The Amazon Resource Name (ARN) of the cluster"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "The name of the cluster"
}

output "cluster_certificate_authority" {
  value       = module.eks.cluster_certificate_authority_data
  description = "The certificate authority of the cluster"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "The endpoint for your Kubernetes API server"
}
