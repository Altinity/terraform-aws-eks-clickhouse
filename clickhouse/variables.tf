variable "clickhouse_operator_path" {
  description = "Path to the operator YAML file (use it to install a different or custom operator version)"
  default     = "./manifests/clickhouse-operator.yaml"
  type        = string
}

variable "clickhouse_cluster_path" {
  description = "Path to the cluster YAML file (use it to install a different or custom cluster version)"
  default     = "./manifests/clickhouse-cluster.yaml.tpl"
  type        = string
}

variable "clickhouse_cluster_name" {
  description = "Name of the ClickHouse cluster"
  default     = "cluster-1"
  type        = string
}

variable "clickhouse_cluster_namespace" {
  description = "Namespace for the ClickHouse cluster"
  default     = "clickhouse"
  type        = string
}

variable "clickhouse_cluster_user" {
  description = "ClickHouse user"
  default     = "test"
  type        = string
}

variable "clickhouse_cluster_password" {
  description = "ClickHouse password"
  type        = string
  default     = null
}
