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

variable "create_vpc" {
  description = "Create dedicated VPC for the EKS cluster"
  type        = bool
  default     = true
}

################################################################################
# VPC
################################################################################
variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  default     = ""
}

variable "subnets" {
  description = "Existing subnets to use ender specified VPC ID"
  type        = list(string)
  default     = [""]
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

    labels = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

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
