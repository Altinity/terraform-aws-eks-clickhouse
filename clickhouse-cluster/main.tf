locals {
  clickhouse_password = var.clickhouse_cluster_password == null ? join("", random_password.this[*].result) : var.clickhouse_cluster_password
}

# Generates a random password without special characters if no password is provided
resource "random_password" "this" {
  count   = var.clickhouse_cluster_password == null ? 1 : 0
  length  = 22
  special = false

  lifecycle {
    # ensures the password isn't regenerated on subsequent applies,
    # preserving the initial password.
    ignore_changes = all
  }
}

# Namespace for all ClickHouse-related Kubernetes resources,
#  providing logical isolation within the cluster.
resource "kubernetes_namespace" "clickhouse" {
  metadata {
    name = var.clickhouse_cluster_namespace
  }
}

resource "helm_release" "clickhouse_cluster" {
  name       = "clickhouse-eks"
  chart      = "clickhouse-eks"
  namespace  = kubernetes_namespace.clickhouse.metadata[0].name
  repository = "https://ianaya89.github.io/clickhouse-hello-chart"
  version    = var.clickhouse_cluster_version

  values = [templatefile("${path.module}/helm/clickhouse-cluster.yaml.tpl", {
    zones         = var.k8s_availability_zones
    instance_type = var.clickhouse_cluster_instance_type
    cluster_name  = var.clickhouse_cluster_name
    service_type  = var.clickhouse_cluster_enable_loadbalancer ? "loadbalancer-external" : "cluster-ip"
    user          = var.clickhouse_cluster_user
    password      = local.clickhouse_password
  })]
}
