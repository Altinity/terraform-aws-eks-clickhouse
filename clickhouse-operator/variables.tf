################################################################################
# ClickHouse Operator
################################################################################
variable "clickhouse_operator_namespace" {
  description = "Namespace to install the Altinity Kubernetes operator for ClickHouse"
  default     = "kube-system"
  type        = string
}

variable "clickhouse_operator_version" {
  description = "Version of the Altinity Kubernetes operator for ClickHouse"
  default     = "0.23.4"
  type        = string
}
