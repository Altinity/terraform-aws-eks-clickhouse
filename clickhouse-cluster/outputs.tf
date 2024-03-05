output "clickhouse_cluster_password" {
  value       = local.clickhouse_password
  description = "The generated password for the ClickHouse cluster"
  sensitive   = true
}

# output "clickhouse_cluster_url" {
#   value       = data.kubernetes_service.clickhouse_load_balancer.status[0].load_balancer[0].ingress[0].hostname
#   description = "The public URL for the ClickHouse cluster"
# }

output "clickhouse_cluster_url" {
  value       = var.wait_for_clickhouse_loadbalancer && length(data.kubernetes_service.clickhouse_load_balancer) > 0 && length(data.kubernetes_service.clickhouse_load_balancer[*].status[*].load_balancer[*].ingress) > 0 ? data.kubernetes_service.clickhouse_load_balancer[0].status[0].load_balancer[0].ingress[0].hostname : "Unknown"
  description = "The public URL for the ClickHouse cluster"
}
