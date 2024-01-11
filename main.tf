provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "this" {
  name = local.cluster_name
  depends_on = [ aws_eks_cluster.this]
}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
  depends_on = [ aws_eks_cluster.this]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.this.token
}


// TODO: Move most of this to variables
locals {
  cluster_version = "1.27"
  region          = "sa-east-1"
  cluster_name    = "nachos-cluster"
  account_id      = data.aws_caller_identity.current.account_id
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)

  image_tag        = "v1.26.1"
  replicas     = 2

  tags = {}

  subnets = [
    { cidr_block = "10.0.1.0/24", az = "sa-east-1a" },
    { cidr_block = "10.0.2.0/24", az = "sa-east-1b" },
    { cidr_block = "10.0.3.0/24", az = "sa-east-1c" }
  ]
}
