locals {
  account_id = data.aws_caller_identity.current.account_id

  subnets = var.create_vpc ? module.vpc.subnets : var.subnets
  vpc_id = var.create_vpc ? module.vpc.vpc_id : var.vpc_id

  # Generate all node pools possible combinations of subnets and instance types
  node_pool_combinations = [for idx, np in flatten([
    for subnet in local.subnets : [
      for itype in var.node_pools_config.instance_types : {
        subnet_id     = subnet
        instance_type = itype
      }
    ]
  ]) : np]
}

module "vpc" {
  source = "./vpc"
  count = var.create_vpc ? 1 : 0

  vpc_name = "${var.cluster_name}-vpc"
  cidr = var.cidr
  public_cidr = var.public_cidr
  private_cidr = var.private_cidr
  enable_nat_gateway = var.enable_nat_gateway
  availability_zones = var.availability_zones

}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = local.vpc_id
  subnet_ids      = local.subnets

  enable_cluster_creator_admin_permissions = true
  create_iam_role                          = false
  iam_role_arn                             = aws_iam_role.eks_cluster_role.arn

  # Node Groups
  eks_managed_node_groups = { for idx, np in local.node_pool_combinations : "node-group-${tostring(idx)}" => {
    desired_capacity = var.node_pools_config.scaling_config.desired_size
    max_capacity     = var.node_pools_config.scaling_config.max_size
    min_capacity     = var.node_pools_config.scaling_config.min_size

    name            = "${var.cluster_name}-${tostring(idx)}"
    use_name_prefix = true

    iam_role_use_name_prefix = false
    create_iam_role          = false
    iam_role_arn             = aws_iam_role.eks_node_role.arn

    instance_types = [np.instance_type]
    subnet_ids     = [np.subnet_id]
    disk_size      = var.node_pools_config.disk_size

    labels = var.node_pools_config.labels
    taints = var.node_pools_config.taints

    tags = merge(
      var.tags,
      {
        "k8s.io/cluster-autoscaler/enabled"             = "true",
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    )
  } }

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  tags = var.tags
}
