locals {
  # Generate all node pools possible combinations of subnets and instance types
  node_pool_combinations = [for idx, np in flatten([
    for subnet in aws_subnet.this : [
      for itype in var.node_pools_config.instance_types : {
        subnet_id     = subnet.id
        instance_type = itype
      }
    ]
  ]) : np]
}

output "node_pool_combinations" {
  value = local.node_pool_combinations
  description = "Node pool combinations based in subnets and instance types"
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_policy" "eks_admin_policy" {
  name        = "${var.cluster_name}-eks-admin-policy"
  description = "EKS Admin Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:CreateCluster",
          "eks:TagResource",
          "eks:DescribeCluster"
        ],
        Resource = "arn:aws:eks:${var.region}:${local.account_id}:cluster/${var.cluster_name}"
      },
      {
        Effect   = "Allow",
        Action   = "iam:CreateServiceLinkedRole",
        Resource = "arn:aws:iam::${local.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
        Condition = {
          "ForAnyValue:StringEquals" = {
            "iam:AWSServiceName" = "eks"
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = aws_iam_role.eks_cluster_role.arn
      },
    ]
  })
}

resource "aws_iam_role" "eks_admin_role" {
  name = "${var.cluster_name}-eks-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        },
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_admin_attach" {
  role       = aws_iam_role.eks_admin_role.name
  policy_arn = aws_iam_policy.eks_admin_policy.arn
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  # The thumbprint for the EKS OIDC Root CA
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-eks-irsa"
    }
  )
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = [for s in aws_subnet.this : s.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
  }

  tags = var.tags
}

resource "aws_eks_node_group" "this" {
  # Creates a node group for each combination of subnet and instance type
  for_each = { for idx, np in local.node_pool_combinations : tostring(idx) => np }

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-node-group-${each.key}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [each.value.subnet_id]

  scaling_config {
    desired_size = var.node_pools_config.scaling_config.desired_size
    max_size     = var.node_pools_config.scaling_config.max_size
    min_size     = var.node_pools_config.scaling_config.min_size
  }

  disk_size      = var.node_pools_config.disk_size
  instance_types = [each.value.instance_type]

  tags = merge(
    var.tags,
    # These tags allow k8s autoscaller to manage the node groups usign the auto-discovery setup
    # https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md#auto-discovery-setup
    {
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      "k8s.io/cluster-autoscaler/${aws_eks_cluster.this.name}" = "owned"
    }
  )
}