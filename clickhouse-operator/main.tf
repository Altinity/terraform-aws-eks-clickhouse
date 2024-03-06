locals {
  clickhouse_operator_yaml = file("${path.module}/${var.clickhouse_operator_manifest_path}")
  # Split operator YAML file into individual manifests
  clickhouse_operator_manifests = split("\n---\n", replace(local.clickhouse_operator_yaml, "\n+", "\n"))
}

# Apply all manifests required to make clickhouse operator work (CRD, Service, ConfigMap, Deployment, etc)
resource "kubectl_manifest" "clickhouse_operator" {
  for_each  = { for doc in local.clickhouse_operator_manifests : sha1(doc) => doc }
  yaml_body = each.value

  override_namespace = var.clickhouse_operator_namespace
}
