provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "this" {
  name = "nachos-eks-cluster"
}

data "aws_eks_cluster_auth" "this" {
  name = "nachos-eks-cluster"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
}

locals {
  cluster_version = "1.27"
  region          = "sa-east-1"
  cluster_name    = "nachos-cluster"
  vpc_cidr = "10.0.0.0/16"
  account_id      = data.aws_caller_identity.current.account_id
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Environment = "prod"
  }
}
