provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.this.token
}

module "eks" {
  source = "./eks"

  providers = {
    aws        = aws
    kubernetes = kubernetes
  }

  replicas            = var.replicas
  image_tag           = var.image_tag
  cluster_name        = var.cluster_name
  region              = var.region
  cidr                = var.cidr
  subnets             = var.subnets
  cluster_version     = var.cluster_version
  public_access_cidrs = var.public_access_cidrs
  tags                = var.tags

  node_pools_config = var.node_pools_config
}

module "clickhouse" {
  source = "./clickhouse"

  providers = {
    kubectl    = kubectl
    kubernetes = kubernetes
  }

  clickhouse_cluster_name      = var.clickhouse_cluster_name
  clickhouse_cluster_namespace = var.clickhouse_cluster_namespace
  clickhouse_cluster_password  = var.clickhouse_cluster_password
  clickhouse_cluster_user      = var.clickhouse_cluster_user
  clickhouse_operator_path     = var.clickhouse_operator_path
  clickhouse_cluster_path      = var.clickhouse_cluster_path

  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
