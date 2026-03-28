locals {
  CLICKHOUSE_NODE_POOL_PREFIX = "clickhouse"
  SYSTEM_NODE_POOL_PREFIX     = "system"

  account_id      = data.aws_caller_identity.current.account_id
  subnets         = var.enable_nat_gateway ? module.vpc.private_subnets : module.vpc.public_subnets
  subnets_by_zone = { for _, subnet in data.aws_subnet.subnets : subnet.availability_zone => subnet.id }

  # ARM-based instance type prefixes (Graviton processors)
  # Comprehensive list of all AWS Graviton instance families (Graviton 1/2/3/4)
  # Reference: https://aws.amazon.com/ec2/instance-types/
  arm_instance_prefixes = [
    # General Purpose
    "a1",          # Graviton (1st gen)
    "t4g",         # Graviton2 burstable
    "m6g", "m6gd", # Graviton2 general purpose
    "m7g", "m7gd", # Graviton3 general purpose
    "m8g",         # Graviton4 general purpose
    # Compute Optimized
    "c6g", "c6gd", "c6gn", # Graviton2 compute optimized
    "c7g", "c7gd", "c7gn", # Graviton3 compute optimized
    "c8g", "c8gn",         # Graviton4 compute optimized
    # Memory Optimized
    "r6g", "r6gd", # Graviton2 memory optimized
    "r7g", "r7gd", # Graviton3 memory optimized
    "r8g",         # Graviton4 memory optimized
    "x2gd",        # Graviton2 high memory
    # Storage Optimized (important for ClickHouse workloads)
    "i4g",         # Graviton2 storage optimized
    "im4gn",       # Graviton2 storage optimized (NVMe)
    "is4gen",      # Graviton2 storage optimized (NVMe)
    "i8g", "i8ge", # Graviton4 storage optimized
    # Accelerated Computing
    "g5g",  # Graviton2 GPU instances
    "hpc7g" # Graviton3E HPC optimized
  ]

  node_pool_defaults = {
    ami_type_x86 = var.default_ami_type
    ami_type_arm = var.default_ami_type_arm
    disk_size    = 20
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  labels = {
    "altinity.cloud/created-by" = "terraform-aws-eks-clickhouse"
  }

  clickhouse_taints = [
    {
      key    = "dedicated"
      value  = "clickhouse"
      effect = "NO_SCHEDULE"
    },
  ]

  # Generate all node pools possible combinations of subnets and node pools
  node_pool_combinations = flatten([
    for np in var.node_pools : [
      for i, zone in(np.zones != null ? np.zones : keys(local.subnets_by_zone)) : [
        {
          name          = np.name != null ? np.name : np.instance_type
          subnet_id     = local.subnets_by_zone[zone]
          instance_type = np.instance_type
          labels        = merge(coalesce(np.labels, {}), local.labels)
          taints        = startswith(np.name, local.CLICKHOUSE_NODE_POOL_PREFIX) ? concat(np.taints, local.clickhouse_taints) : np.taints

          desired_size = np.desired_size == null ? (
            local.node_pool_defaults.desired_size
            ) : (
            startswith(np.name, local.SYSTEM_NODE_POOL_PREFIX) && i == 0 && np.desired_size == 0 ? (
              local.node_pool_defaults.desired_size
              ) : (
              np.desired_size
            )
          )
          max_size  = np.max_size != null ? np.max_size : local.node_pool_defaults.max_size
          min_size  = np.min_size != null ? np.min_size : local.node_pool_defaults.min_size
          disk_size = np.disk_size != null ? np.disk_size : local.node_pool_defaults.disk_size

          # Automatically detect ARM-based instances and use appropriate AMI type
          ami_type = np.ami_type != null ? np.ami_type : (
            contains([for prefix in local.arm_instance_prefixes : prefix if startswith(np.instance_type, prefix)], split(".", np.instance_type)[0]) ?
            local.node_pool_defaults.ami_type_arm :
            local.node_pool_defaults.ami_type_x86
          )

          tags = np.tags
        }
      ]
    ]
  ])
}

data "aws_subnet" "subnets" {
  for_each = { for idx, subnet_id in local.subnets : idx => subnet_id }
  id       = each.value

  lifecycle {
    precondition {
      condition     = length(var.public_cidr) == length(var.availability_zones)
      error_message = "The number of public CIDRs (${length(var.public_cidr)}) must match the number of availability zones (${length(var.availability_zones)})."
    }
    precondition {
      condition     = !var.enable_nat_gateway || length(var.private_cidr) == length(var.availability_zones)
      error_message = "The number of private CIDRs (${length(var.private_cidr)}) must match the number of availability zones (${length(var.availability_zones)})."
    }
    precondition {
      condition = alltrue([
        for np in var.node_pools : alltrue([
          for zone in coalesce(np.zones, []) : contains(var.availability_zones, zone)
        ])
      ])
      error_message = "All zones specified in node_pools must be included in the availability_zones list."
    }
  }
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
    disk_size      = np.disk_size
    ami_type       = np.ami_type

    labels = np.labels
    taints = np.taints

    tags = merge(
      var.tags,
      np.tags,
      {
        "k8s.io/cluster-autoscaler/enabled"             = "true",
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      }
    )
  } }

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  # Secrets encryption
  create_kms_key            = var.enable_secrets_encryption
  cluster_encryption_config = var.enable_secrets_encryption ? { resources = ["secrets"] } : {}

  # Control plane logging
  cluster_enabled_log_types = var.cluster_enabled_log_types

  tags = var.tags
}
