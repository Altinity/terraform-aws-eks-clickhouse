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

# Deploys the ClickHouse cluster using a custom resource definition (CRD),
#  defined by the ClickHouse operator.
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

resource "null_resource" "wait_for_clickhouse" {
  depends_on = [kubectl_manifest.clickhouse_cluster]

  provisioner "local-exec" {
    command = <<EOF
    until kubectl get svc/${var.clickhouse_cluster_namespace}-${var.clickhouse_cluster_name} -n ${var.clickhouse_cluster_namespace} 2>&1 | grep -m 1 "LoadBalancer"; do
      echo "Waiting for ClickHouse service to be available..."
      sleep 10
    done
    EOF
  }
}

data "kubernetes_service" "clickhouse_load_balancer" {
  depends_on = [null_resource.wait_for_clickhouse]

  metadata {
    name      = "${var.clickhouse_cluster_namespace}-${var.clickhouse_cluster_name}"
    namespace = var.clickhouse_cluster_namespace
  }
}
