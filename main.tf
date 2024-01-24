provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "this" {
  name       = var.cluster_name
  depends_on = [aws_eks_cluster.this]
}

data "aws_eks_cluster_auth" "this" {
  name       = var.cluster_name
  depends_on = [aws_eks_cluster.this]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
}


locals {
  account_id = data.aws_caller_identity.current.account_id
}
