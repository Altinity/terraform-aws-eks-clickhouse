variable "clickhouse_operator_manifest_path" {
  description = "Path to the operator YAML file (use it to install a different or custom operator version)"
  default     = "./manifests/clickhouse-operator.yaml"
  type        = string
}

variable "clickhouse_operator_namespace" {
  description = "Namespace for the clickhouse operator"
  default     = "kube-system"
  type        = string
}
