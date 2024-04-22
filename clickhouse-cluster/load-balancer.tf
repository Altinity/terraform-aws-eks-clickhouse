locals {
  kubeconfig = <<EOT
    apiVersion: v1
    kind: Config
    clusters:
    - cluster:
        certificate-authority-data: ${base64encode(var.k8s_cluster_certificate_authority)}
        server: ${var.k8s_cluster_endpoint}
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
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          command: aws
          args:
            - "eks"
            - "get-token"
            - "--cluster-name"
            - "${var.k8s_cluster_name}"
            - "--region"
            - "${var.k8s_cluster_region}"
    EOT
}


# This is a "hack" wich waits for the ClickHouse cluster to receive a hostname from the LoadBalancer service.
resource "null_resource" "wait_for_clickhouse" {
  depends_on = [helm_release.clickhouse_cluster]
  count      = var.clickhouse_cluster_enable_loadbalancer ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      KUBECONFIG_PATH=$(mktemp)
      echo '${local.kubeconfig}' > $KUBECONFIG_PATH
      NAMESPACE=${var.clickhouse_cluster_namespace}
      SECONDS=0
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
  count      = var.clickhouse_cluster_enable_loadbalancer ? 1 : 0

  metadata {
    name      = "clickhouse-eks"
    namespace = var.clickhouse_cluster_namespace
  }
}
