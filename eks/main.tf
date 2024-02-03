locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "this" {
  name       = var.cluster_name
  depends_on = [aws_eks_cluster.this]
}

data "aws_eks_cluster_auth" "this" {
  name       = var.cluster_name
  depends_on = [aws_eks_cluster.this]
}
