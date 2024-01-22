resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.cluster_name}-eks-cluster-role"

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
  name        = "${local.cluster_name}-eks-admin-policy"
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
        Resource = "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.cluster_name}"
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
  name = "${local.cluster_name}-eks-admin-role"

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
  name = "${local.cluster_name}-eks-node-role"

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

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = local.cluster_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = [for s in aws_subnet.this : s.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = length(local.public_access_cidrs) > 0 ? local.public_access_cidrs : ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  # The thumbprint for the EKS OIDC Root CA
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

  tags = {
    Name = "${local.cluster_name}-eks-irsa"
  }
}

resource "random_string" "node_group_name" {
  length  = 6
  lower   = true
  upper   = false
  special = false
}

resource "aws_eks_node_group" "this" {
  count = length(aws_subnet.this)

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-node-group-${count.index}-${random_string.node_group_name.result}"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.this[count.index].id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = local.instance_types
  disk_size      = 20

  tags = merge(
    local.tags,
    {
      "k8s.io/cluster-autoscaler/enabled"                      = "true",
      "k8s.io/cluster-autoscaler/${aws_eks_cluster.this.name}" = "owned"
    }
  )
}

