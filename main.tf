provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "this" {
  name       = local.cluster_name
  depends_on = [aws_eks_cluster.this]
}

data "aws_eks_cluster_auth" "this" {
  name       = local.cluster_name
  depends_on = [aws_eks_cluster.this]
}

provider "kubernetes" {
  config_path            = "~/.kube/config"
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
  config_context         = data.aws_eks_cluster.this.arn
}

// TODO: Move most of this to variables
locals {
  region       = "us-east-1"
  cluster_name = "clickhouse-cluster"
  account_id   = data.aws_caller_identity.current.account_id
  azs          = slice(data.aws_availability_zones.available.names, 0, 3)

  cluster_version = "1.26"
  image_tag       = "v1.26.1"
  replicas        = 2

  tags = {}

  cidr = "10.0.0.0/16"
  subnets = [
    { cidr_block = "10.0.1.0/24", az = "us-east-1a" },
    { cidr_block = "10.0.2.0/24", az = "us-east-1b" },
    { cidr_block = "10.0.3.0/24", az = "us-east-1c" }
  ]

  public_access_cidrs = []
  instance_types      = ["m5.large"]
}
