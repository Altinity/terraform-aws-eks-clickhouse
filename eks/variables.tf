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
  default = {
    CreatedBy = "nacho"
  }
}

variable "cidr" {
  description = "CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

// Should this be retrieved automatically based on region and CIDR?
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
