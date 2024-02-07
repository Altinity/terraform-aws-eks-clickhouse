locals {
  clickhouse_password = var.clickhouse_cluster_password == null ? join("", random_password.this[*].result) : var.clickhouse_cluster_password
}

# Create a random password for clickhouse if one is not provided`
resource "random_password" "this" {
  count   = var.clickhouse_cluster_password == null ? 1 : 0
  length  = 22
  special = false

  lifecycle {
    ignore_changes = all
  }
}

# Create a namespace for allocating the clickhouse cluster
resource "kubernetes_namespace" "clickhouse" {
  metadata {
    name = var.clickhouse_cluster_namespace
  }
}

# Create a clickhouse cluster, this will spin up a new ClickHouseInstallation custom resource.
resource "kubectl_manifest" "clickhouse_cluster" {
  depends_on = [kubernetes_namespace.clickhouse]

  yaml_body = templatefile("${path.module}/${var.clickhouse_cluster_manifest_path}", {
    name                = var.clickhouse_cluster_name
    namespace           = var.clickhouse_cluster_namespace
    user                = var.clickhouse_cluster_user
    password            = local.clickhouse_password
    zookeeper_namespace = var.zookeeper_namespace
  })
}

data "kubernetes_service" "clickhouse_load_balancer" {
  depends_on = [kubectl_manifest.clickhouse_cluster]

  metadata {
    name      = "${var.clickhouse_cluster_namespace}-${var.clickhouse_cluster_name}"
    namespace = var.clickhouse_cluster_namespace
  }
}
