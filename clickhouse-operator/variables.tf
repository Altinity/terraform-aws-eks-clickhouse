################################################################################
# ClickHouse Operator
################################################################################
variable "clickhouse_operator_namespace" {
  description = "Namespace to install the clickhouse operator"
  default     = "kube-system"
  type        = string
}

variable "clickhouse_operator_version" {
  description = "Version of the clickhouse operator"
  default     = "0.23.4"
  type        = string
}
