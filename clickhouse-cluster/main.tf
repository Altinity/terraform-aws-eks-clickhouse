locals {
  clickhouse_password = var.clickhouse_cluster_password == null ? join("", random_password.this[*].result) : var.clickhouse_cluster_password

  zookeeper_cluster_yaml = file("${path.module}/${var.zookeeper_cluster_manifest_path}")
  # Split operator YAML file into individual manifests
  zookeeper_cluster_manifests = split("\n---\n", replace(local.zookeeper_cluster_yaml, "\n+", "\n"))

  kubeconfig = <<EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority-data: ${base64encode(var.cluster_certificate_authority)}
        server: ${var.cluster_endpoint}
      name: eks-cluster
    contexts:
    - context:
        cluster: eks-cluster
        user: eks-user
      name: eks-context
    current-context: eks-context
    users:
    - name: eks-user
      user:
        ${var.kubeconfig_user_exec}
    EOT
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

# Setups a single node Zookeeper cluster
resource "kubectl_manifest" "zookeeper_cluster" {
  for_each  = { for doc in local.zookeeper_cluster_manifests : sha1(doc) => doc }
  yaml_body = each.value

  override_namespace = kubernetes_namespace.clickhouse.metadata[0].name
}

# Deploys the ClickHouse cluster using a custom resource definition (CRD),
#  defined by the ClickHouse operator.
resource "kubectl_manifest" "clickhouse_cluster" {
  yaml_body = templatefile("${path.module}/${var.clickhouse_cluster_manifest_path}", {
    name           = var.clickhouse_cluster_name
    namespace      = kubernetes_namespace.clickhouse.metadata[0].name
    user           = var.clickhouse_cluster_user
    password       = local.clickhouse_password
    instance_type  = var.instance_type
    replicas_count = var.replicas_count
    shards_count   = var.shards_count
  })
}

# This is a "hack" wich waits for the ClickHouse cluster to receive a hostname from the LoadBalancer service.
resource "null_resource" "wait_for_clickhouse" {
  depends_on = [kubectl_manifest.clickhouse_cluster]
  count      = var.wait_for_clickhouse_loadbalancer ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      KUBECONFIG_PATH=$(mktemp)
      echo '${local.kubeconfig}' > $KUBECONFIG_PATH
      NAMESPACE=${var.clickhouse_cluster_namespace}
      SLEEP_TIME=10
      TIMEOUT=600

      end=$((SECONDS+TIMEOUT))
      echo "Waiting for cluster in the namespace $NAMESPACE to receive a hostname..."

      while [ $SECONDS -lt $end ]; do
          HOSTNAME=$(kubectl --kubeconfig $KUBECONFIG_PATH get service --namespace=$NAMESPACE -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].hostname}' | awk '{print $1}')
          if [ -n "$HOSTNAME" ]; then
              echo "Cluster has received a hostname: $HOSTNAME"
              exit 0
          fi
          echo "Cluster does not have a hostname yet. Rechecking in $SLEEP_TIME seconds..."
          sleep $SLEEP_TIME
      done

      echo "Timed out waiting for cluster to receive a hostname in namespace $NAMESPACE."
      exit 1
    EOT
  }
}

data "kubernetes_service" "clickhouse_load_balancer" {
  depends_on = [null_resource.wait_for_clickhouse]
  count      = var.wait_for_clickhouse_loadbalancer ? 1 : 0

  metadata {
    name      = "${var.clickhouse_cluster_namespace}-${var.clickhouse_cluster_name}"
    namespace = var.clickhouse_cluster_namespace
  }
}

resource "null_resource" "pre_destroy" {
  count = var.wait_for_clickhouse_loadbalancer ? 1 : 0

  triggers = {
    kubeconfig = "${local.kubeconfig}"
    namespace  = var.clickhouse_cluster_namespace
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      KUBECONFIG_PATH=$(mktemp)
      echo '${self.triggers.kubeconfig}' > $KUBECONFIG_PATH
      NAMESPACE="${self.triggers.namespace}"

      while kubectl --kubeconfig $KUBECONFIG_PATH get service --namespace $NAMESPACE; do
        echo "Waiting for ClickHouse LoadBalancer deletion..."
        sleep 10
      done

      rm $KUBECONFIG_PATH
    EOT
  }
}