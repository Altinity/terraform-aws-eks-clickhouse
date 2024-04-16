resource "helm_release" "altinity_clickhouse_operator" {
  name       = "altinity-clickhouse-operator"
  chart      = "altinity-clickhouse-operator"
  repository = "https://altinity.github.io/clickhouse-operator"

  version   = var.clickhouse_operator_version
  namespace = var.clickhouse_operator_namespace
}
