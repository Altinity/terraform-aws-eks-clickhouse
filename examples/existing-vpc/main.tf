locals {
  region = "us-east-1"
}

module "eks_clickhouse" {
  source = "../../"

  install_clickhouse_operator = true
  install_clickhouse_cluster  = true

  # Set to true if you want to use new VPC. If set to false vpc_id and subnets should be provided
  create_vpc = false

  vpc_id = "vpc-07ba741c417728bef"
  eks_subnets = ["subnet-0a200c0addca7215a", "subnet-0ffcdc4ae84693b5n"]

  # Set to true if you want to use a public load balancer (and expose ports to the public Internet)
  clickhouse_cluster_enable_loadbalancer = false

  eks_cluster_name = "clickhouse-cluster"
  eks_region       = local.region

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
