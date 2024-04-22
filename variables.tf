################################################################################
# GLOBAL
################################################################################

variable "install_clickhouse_cluster" {
  description = "Enable the installation of the ClickHouse cluster"
  type        = bool
  default     = true
}

variable "install_clickhouse_keeper" {
  description = "Enable the installation of the ClickHouse Keeper cluster"
  type        = bool
  default     = true
}

variable "install_clickhouse_operator" {
  description = "Enable the installation of the ClickHouse operator"
  type        = bool
  default     = true
}

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


################################################################################
# ClickHouse Cluster
################################################################################
# variable "clickhouse_cluster_name" {
#   description = "Name of the ClickHouse cluster"
#   default     = "eks"
#   type        = string
# }

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

variable "clickhouse_cluster_enable_loadbalancer" {
  description = "Enable waiting for the ClickHouse LoadBalancer to receive a hostname"
  type        = bool
  default     = false
}

################################################################################
# EKS
################################################################################
variable "eks_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "clickhouse-cluster"
}

variable "eks_cluster_version" {
  description = "Version of the cluster"
  type        = string
  default     = "1.26"
}

variable "eks_autoscaler_version" {
  description = "Version of AWS Autoscaler"
  type        = string
  default     = "1.26.1"
}

variable "eks_tags" {
  description = "A map of tags"
  type        = map(string)
  default     = {}
}

variable "eks_cidr" {
  description = "CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_node_pools_config" {
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

variable "eks_public_access_cidrs" {
  description = "List of CIDRs for public access, use this variable to restrict access to the EKS control plane."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}



variable "eks_enable_nat_gateway" {
  description = "TBA"
  type        = bool
  default     = true
}

variable "eks_private_cidr" {
  description = "List of private CIDR"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "eks_public_cidr" {
  description = "List of public CIDR"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]
}

variable "eks_availability_zones" {
  description = ""
  type        = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}
