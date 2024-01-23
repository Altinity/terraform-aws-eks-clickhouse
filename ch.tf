// TODO: Deploy clickhouse operator

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}

resource "kubernetes_manifest" "clickhouse_cluster" {
  manifest = yamldecode(file("${path.module}/ch.yaml"))
  depends_on = [kubernetes_namespace.test]
}
