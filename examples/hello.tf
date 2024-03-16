locals {
  region = "us-east-1"
}

module "eks_clickhouse" {
  source = "github.com/Altinity/terraform-aws-eks-clickhouse"

  install_clickhouse_operator = true
  install_clickhouse_cluster  = true

  cluster_name = "clickhouse-cluster"
  region       = local.region
  cidr         = "10.0.0.0/16"
  subnets = [
    { cidr_block = "10.0.1.0/24", az = "${local.region}a" },
    { cidr_block = "10.0.2.0/24", az = "${local.region}b" },
    { cidr_block = "10.0.3.0/24", az = "${local.region}c" }
  ]

  node_pools_config = {
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 0
    }

    disk_size      = 20
    instance_types = ["m5.large"]
  }

  tags = {
    CreatedBy = "mr-robot"
  }
}

output "clickhouse_cluster_url" {
  value = module.eks_clickhouse.clickhouse_cluster_url
}

output "clickhouse_cluster_password" {
  value     = module.eks_clickhouse.clickhouse_cluster_password
  sensitive = true
}
