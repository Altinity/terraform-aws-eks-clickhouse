locals {
  region = "us-east-1"
}

provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = local.region
}


module "eks_clickhouse" {
  source = "github.com/Altinity/terraform-aws-eks-clickhouse"

  install_clickhouse_operator = true
  install_clickhouse_cluster  = true
  eks_enable_nat_gateway      = false

  eks_cluster_name = "clickhouse-cluster"
  eks_region       = local.region
  eks_cidr         = "10.0.0.0/16"

  eks_availability_zones = [
    "${local.region}a",
    "${local.region}b",
    "${local.region}c"
  ]
  eks_public_cidr = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]
  eks_node_pools_config = {
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 0
    }

    disk_size      = 20
    instance_types = ["m5.large"]
  }

  eks_tags = {
    CreatedBy = "mr-robot"
  }
}

output "eks_configure_kubectl" {
  value = module.eks_clickhouse.eks_configure_kubectl
}
