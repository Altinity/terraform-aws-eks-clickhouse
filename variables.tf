################################################################################
# EKS
################################################################################
variable "install_clickhouse_cluster" {
  description = "Enable the installation of the ClickHouse cluster"
  type        = bool
  default     = true
}

variable "install_clickhouse_operator" {
  description = "Enable the installation of the ClickHouse operator"
  type        = bool
  default     = true
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "clickhouse-cluster"
}

variable "cluster_version" {
  description = "Version of the cluster"
  type        = string
  default     = "1.26"
}

variable "image_tag" {
  description = "Image tag"
  type        = string
  default     = "v1.26.1"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 2
}

variable "tags" {
  description = "A map of tags"
  type        = map(string)
  default     = {}
}

variable "cidr" {
  description = "CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnets" {
  description = "List of subnets"
  type        = list(map(string))
  default = [
    { cidr_block = "10.0.1.0/24", az = "us-east-1a" },
    { cidr_block = "10.0.2.0/24", az = "us-east-1b" },
    { cidr_block = "10.0.3.0/24", az = "us-east-1c" }
  ]
}

variable "node_pools_config" {
  description = "Node pools configuration. The module will create a node pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different node pools."

  type = object({
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })

    disk_size      = number
    instance_types = list(string)
  })

  default = {
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 0
    }

    disk_size      = 20
    instance_types = ["m5.large"]
  }
}

variable "public_access_cidrs" {
  description = "List of CIDRs for public access, use this variable to restrict access to the EKS control plane."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

################################################################################
# ClickHouse Operator
################################################################################
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

################################################################################
# ClickHouse Cluster
################################################################################
variable "clickhouse_cluster_manifest_path" {
  description = "Path to the cluster YAML file (use it to install a different or custom cluster version)"
  default     = "./manifests/clickhouse-cluster.yaml.tpl"
  type        = string
}

variable "clickhouse_cluster_name" {
  description = "Name of the ClickHouse cluster"
  default     = "chi"
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

variable "clickhouse_cluster_wait_for_loadbalancer" {
  description = "Enable waiting for the ClickHouse LoadBalancer to receive a hostname"
  type        = bool
  default     = true
}

variable "clickhouse_cluster_replicas_count" {
  description = "The number of replicas for the ClickHouse cluster"
  type        = number
  default     = 1
}

variable "clickhouse_cluster_shards_count" {
  description = "The number of shards for the ClickHouse cluster"
  type        = number
  default     = 1
}

variable "zookeeper_cluster_manifest_path" {
  description = "Path to the zookeeper cluster YAML file (use it to install a different or custom cluster version)"
  default     = "./manifests/zookeeper-cluster.yaml"
  type        = string
}
