locals {
  region = "us-east-1"
}

provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = local.region
}

module "eks_clickhouse" {
  source = "github.com/Altinity/terraform-aws-eks-clickhouse?ref=v0.5.7"

  install_clickhouse_operator = true
  install_clickhouse_cluster  = true

  # Set to true if you want to use a public load balancer (and expose ports to the public Internet)
  clickhouse_cluster_enable_loadbalancer = false

  eks_cluster_name = "clickhouse-cluster"
  eks_region       = local.region
  eks_cidr         = "10.0.0.0/16"

  eks_availability_zones = [
    "${local.region}a",
    "${local.region}b",
    "${local.region}c"
  ]
  eks_private_cidr = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  eks_public_cidr = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]

  # Optional: Customize AMI types for x86_64 and ARM64 instances
  # eks_default_ami_type     = "AL2023_x86_64_STANDARD"  # Default for x86_64 instances
  # eks_default_ami_type_arm = "AL2023_ARM_64_STANDARD"  # Default for ARM64 instances (t4g, m7g, etc.)

  # ⚠️ The instance type of the first node pool with the "clickhouse" name prefix will be used for the ClickHouse cluster replicas.
  eks_node_pools = [
    {
      name          = "clickhouse"
      instance_type = "m6i.large"
      desired_size  = 0
      max_size      = 10
      min_size      = 0
      zones         = ["${local.region}a", "${local.region}b", "${local.region}c"]
    },
    {
      name          = "system"
      instance_type = "t3.large"
      desired_size  = 1
      max_size      = 10
      min_size      = 0
      zones         = ["${local.region}a"]
    }
  ]

  eks_tags = {
    CreatedBy = "mr-robot"
  }
}

output "eks_configure_kubectl" {
  value = module.eks_clickhouse.eks_configure_kubectl
}
