locals {
  account_id = data.aws_caller_identity.current.account_id

  zones           = { for k, v in data.aws_subnet.subnets : k => v.availability_zone }
  subnets_by_zone = { for id, subnet in data.aws_subnet.subnets : subnet.availability_zone => id }
  subnets         = var.enable_nat_gateway ? module.vpc.private_subnets : module.vpc.public_subnets

  # Generate all node pools possible combinations of subnets and node pools
  node_pool_combinations = flatten([
    for np in var.node_pools : [
      for zone in(np.zones != null ? np.zones : keys(local.subnets_by_zone)) : [
        {
          name          = np.name
          subnet_id     = local.subnets_by_zone[zone]
          instance_type = np.instance_type
          labels        = np.labels
          taints        = np.taints
          ami_type      = np.ami_type
          desired_size  = np.desired_size
          max_size      = np.max_size
          min_size      = np.min_size
          disk_size     = np.disk_size
        }
      ]
    ]
  ])

  node_pool_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 20
  }
}

data "aws_subnet" "subnets" {
  for_each = toset(local.subnets)
  id       = each.value
}

output "vpc" {
  value = local.subnets_by_zone
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = local.subnets

  enable_cluster_creator_admin_permissions = true
  create_iam_role                          = false
  iam_role_arn                             = aws_iam_role.eks_cluster_role.arn

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # Node Groups
  eks_managed_node_groups = { for idx, np in local.node_pool_combinations : "node-group-${tostring(idx)}" => {
    desired_size = np.desired_size
    max_size     = np.max_size
    min_size     = np.min_size

    name            = np.name
    use_name_prefix = true

    iam_role_use_name_prefix = false
    create_iam_role          = false
    iam_role_arn             = aws_iam_role.eks_node_role.arn

    instance_types = [np.instance_type]
    subnet_ids     = [np.subnet_id]
    disk_size      = np.disk_size != null ? np.disk_size : local.node_pool_defaults.disk_size
    ami_type       = np.ami_type != null ? np.ami_type : local.node_pool_defaults.ami_type

    labels = np.labels
    taints = np.taints

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
