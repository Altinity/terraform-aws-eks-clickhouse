locals {
  clickhouse_cluster_chart_name     = "clickhouse-eks"
  clickhouse_keeper_chart_name      = "clickhouse-keeper-sts"
  clickhouse_helm_charts_repository = "https://helm.altinity.com"
  clickhouse_password               = var.clickhouse_cluster_password == null ? join("", random_password.this[*].result) : var.clickhouse_cluster_password
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


resource "helm_release" "clickhouse_keeper" {
  name       = local.clickhouse_keeper_chart_name
  chart      = local.clickhouse_keeper_chart_name
  namespace  = kubernetes_namespace.clickhouse.metadata[0].name
  repository = local.clickhouse_helm_charts_repository
  version    = var.clickhouse_keeper_chart_version
}


resource "helm_release" "clickhouse_cluster" {
  name       = local.clickhouse_cluster_chart_name
  chart      = local.clickhouse_cluster_chart_name
  namespace  = kubernetes_namespace.clickhouse.metadata[0].name
  repository = local.clickhouse_helm_charts_repository
  version    = var.clickhouse_cluster_chart_version

  values = [templatefile("${path.module}/helm/clickhouse-cluster.yaml.tpl", {
    zones         = var.k8s_availability_zones
    instance_type = var.clickhouse_cluster_instance_type
    name          = var.clickhouse_name
    cluster_name  = var.clickhouse_cluster_name
    service_type  = var.clickhouse_cluster_enable_loadbalancer ? "loadbalancer-external" : "cluster-ip"
    user          = var.clickhouse_cluster_user
    password      = local.clickhouse_password
  })]
}
