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
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway and private subnets (recommended)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs. Set to false to create one NAT Gateway per AZ for higher availability"
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
  default     = "1.34"
}

variable "autoscaler_version" {
  description = "Autoscaler version"
  type        = string
  default     = "1.34.0"
}

variable "default_ami_type" {
  description = "Default AMI type for x86_64 node groups"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "default_ami_type_arm" {
  description = "Default AMI type for ARM64 node groups"
  type        = string
  default     = "AL2023_ARM_64_STANDARD"
}

variable "autoscaler_replicas" {
  description = "Autoscaler replicas"
  type        = number
  default     = 1
}

variable "node_pools" {
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
      ami_type      = null # Uses default_ami_type when null
      desired_size  = 0
      max_size      = 10
      min_size      = 0
      disk_size     = 20
      zones         = ["us-east-1a", "us-east-1b", "us-east-1c"]
    },
    {
      name          = "system"
      instance_type = "t3.large"
      ami_type      = null # Uses default_ami_type when null
      desired_size  = 1
      max_size      = 10
      min_size      = 0
      disk_size     = 20
      zones         = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }
  ]

  validation {
    condition = alltrue([
      for np in var.node_pools :
      startswith(np.name, "clickhouse") || startswith(np.name, "system")
    ])
    error_message = "Each node pool name must start with either 'clickhouse' or 'system' prefix."
  }
}

variable "endpoint_public_access" {
  description = "Enable public access to the EKS cluster API endpoint"
  type        = bool
  default     = true
}

variable "enable_secrets_encryption" {
  description = "Enable envelope encryption for Kubernetes secrets using a KMS key"
  type        = bool
  default     = false
}

variable "cluster_enabled_log_types" {
  description = "List of EKS control plane log types to enable. Valid values: api, audit, authenticator, controllerManager, scheduler"
  type        = list(string)
  default     = []
}

variable "public_access_cidrs" {
  description = "List of CIDRs for public access, use this variable to restrict access to the EKS control plane."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
