provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = module.eks.cluster_token
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = module.eks.cluster_token
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

module "clickhouse_operator" {
  source = "./clickhouse-operator"

  providers = {
    kubectl    = kubectl
    kubernetes = kubernetes
  }

  clickhouse_operator_manifest_path = var.clickhouse_operator_manifest_path
  zookeeper_cluster_manifest_path   = var.zookeeper_cluster_manifest_path
  clickhouse_operator_namespace     = var.clickhouse_operator_namespace
  zookeeper_namespace               = var.zookeeper_namespace

  depends_on = [module.eks]
}

module "clickhouse_cluster" {
  source = "./clickhouse-cluster"

  providers = {
    kubectl    = kubectl
    kubernetes = kubernetes
  }

  clickhouse_cluster_name          = var.clickhouse_cluster_name
  clickhouse_cluster_namespace     = var.clickhouse_cluster_namespace
  clickhouse_cluster_password      = var.clickhouse_cluster_password
  clickhouse_cluster_user          = var.clickhouse_cluster_user
  clickhouse_cluster_manifest_path = var.clickhouse_cluster_manifest_path

  depends_on = [module.clickhouse_operator]
}


