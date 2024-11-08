################################################################################
# GLOBAL
################################################################################
variable "install_clickhouse_cluster" {
  description = "Enable the installation of the ClickHouse cluster"
  type        = bool
  default     = true
}

variable "install_clickhouse_operator" {
  description = "Enable the installation of the Altinity Kubernetes operator for ClickHouse"
  type        = bool
  default     = true
}

variable "aws_profile" {
  description = "AWS profile of deployed cluster."
  type        = string
  default     = null
}

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


################################################################################
# ClickHouse Cluster
################################################################################
variable "clickhouse_cluster_name" {
  description = "Name of the ClickHouse cluster"
  default     = "dev"
  type        = string
}

variable "clickhouse_cluster_namespace" {
  description = "Namespace of the ClickHouse cluster"
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
  default     = "1.29"
}

variable "eks_autoscaler_version" {
  description = "Version of AWS Autoscaler"
  type        = string
  default     = "1.29.2"
}

variable "eks_autoscaler_replicas" {
  description = "Number of replicas for AWS Autoscaler"
  type        = number
  default     = 1
}

variable "autoscaler_replicas" {
  description = "Autoscaler replicas"
  type        = number
  default     = 1
}

variable "eks_tags" {
  description = "A map of AWS tags"
  type        = map(string)
  default     = {}
}

variable "eks_cidr" {
  description = "CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "eks_node_pools" {
  description = "Node pools configuration. The module will create a node pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different node pools."

  type = list(object({
    name          = string
    instance_type = string
    ami_type      = optional(string)
    disk_size     = optional(number)
    desired_size  = number
    max_size      = number
    min_size      = number
    zones         = optional(list(string))

    labels = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))

  default = [
    {
      name          = "clickhouse"
      instance_type = "m6i.large"
      ami_type      = "AL2_x86_64"
      desired_size  = 0
      disk_size     = 20
      max_size      = 10
      min_size      = 0
      zones         = ["us-east-1a", "us-east-1b", "us-east-1c"]
    },
    {
      name          = "system"
      instance_type = "t3.large"
      ami_type      = "AL2_x86_64"
      disk_size     = 20
      desired_size  = 1
      max_size      = 10
      min_size      = 0
      zones         = ["us-east-1a"]
    }
  ]

  validation {
    condition = alltrue([
      for np in var.eks_node_pools :
      startswith(np.name, "clickhouse") || startswith(np.name, "system")
    ])
    error_message = "Each node pool name must start with either 'clickhouse' or 'system' prefix."
  }
}

variable "eks_enable_nat_gateway" {
  description = "Enable NAT Gateway and private subnets (recommeded)"
  type        = bool
  default     = true
}

variable "eks_private_cidr" {
  description = "List of private CIDR. When set, the number of private CIDRs must match the number of availability zones"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "eks_public_cidr" {
  description = "List of public CIDR. When set, The number of public CIDRs must match the number of availability zones"
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

variable "eks_public_access_cidrs" {
  description = "List of CIDRs for public access, use this variable to restrict access to the EKS control plane."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
