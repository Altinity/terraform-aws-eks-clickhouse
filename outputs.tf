output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "clickhouse_cluster_password" {
  value       = module.clickhouse.clickhouse_cluster_password
  description = "The generated password for the ClickHouse cluster"
  sensitive   = true
}

output "clickhouse_cluter_url" {
  value       = module.clickhouse.clickhouse_cluter_url
  description = "The public URL for the ClickHouse cluster"
}