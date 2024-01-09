resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  version  = 1.26
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = [for s in aws_subnet.this : s.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }
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

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "node-group-1"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [for s in aws_subnet.this : s.id]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  disk_size      = 20
}
