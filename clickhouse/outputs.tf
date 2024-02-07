output "clickhouse_cluster_password" {
  value       = local.clickhouse_password
  description = "The generated password for the ClickHouse cluster"
  sensitive   = true
}

output "clickhouse_cluter_url" {
  value       = data.kubernetes_service.clickhouse_load_balancer.status[0].load_balancer[0].ingress[0].hostname
  description = "The public URL for the ClickHouse cluster"
}