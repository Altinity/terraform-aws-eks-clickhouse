################################################################################
# Global
################################################################################
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

variable "vpc_name" {
  description = "The name of the cluster"
  type        = string
  default     = "clickhouse-cluster"
}


