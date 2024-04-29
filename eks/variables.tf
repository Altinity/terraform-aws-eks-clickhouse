################################################################################
# Global
################################################################################
variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Map with AWS tags"
  type        = map(string)
  default     = {}
}

################################################################################
# VPC
################################################################################
variable "cidr" {
  description = "CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_cidr" {
  description = "List of private CIDR blocks (one block per availability zones)"
  type        = list(string)
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "public_cidr" {
  description = "List of public CIDR blocks (one block per availability zones)"
  type        = list(string)
  default = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]
}

variable "availability_zones" {
  description = "List of AWS availability zones"
  type        = list(string)
  default = [
    "us-east-1",
    "us-east-2",
    "us-east-3"
  ]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway and private subnets (recommeded)"
  type        = bool
  default     = true
}

################################################################################
# EKS
################################################################################
variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
  default     = "clickhouse-cluster"
}

variable "cluster_version" {
  description = "Version of the cluster"
  type        = string
  default     = "1.28"
}

variable "autoscaler_version" {
  description = "Autoscaler version"
  type        = string
  default     = "1.28.4"
}

variable "node_pools_config" {
  description = "Node pools configuration. The module will create a node pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different node pools."

  type = object({
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })

    labels = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))

    disk_size      = number
    instance_types = list(string)
  })

  default = {
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 0
    }

    labels = {}
    taints = []

    disk_size      = 20
    instance_types = ["m5.large"]
  }
}

variable "public_access_cidrs" {
  description = "List of CIDRs for public access, use this variable to restrict access to the EKS control plane."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
