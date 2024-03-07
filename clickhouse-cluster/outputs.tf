output "clickhouse_cluster_password" {
  value       = local.clickhouse_password
  description = "The generated password for the ClickHouse cluster"
  sensitive   = true
}

output "clickhouse_cluster_url" {
  value       = var.clickhouse_cluster_wait_for_loadbalancer && length(data.kubernetes_service.clickhouse_load_balancer) > 0 && length(data.kubernetes_service.clickhouse_load_balancer[*].status[*].load_balancer[*].ingress) > 0 ? data.kubernetes_service.clickhouse_load_balancer[0].status[0].load_balancer[0].ingress[0].hostname : "Unknown"
  description = "The public URL for the ClickHouse cluster"
}
