provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

module "eks" {
  source = "./eks"

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

  clickhouse_operator_manifest_path = var.clickhouse_operator_manifest_path
  zookeeper_cluster_manifest_path   = var.zookeeper_cluster_manifest_path
  clickhouse_operator_namespace     = var.clickhouse_operator_namespace
  zookeeper_namespace               = var.zookeeper_namespace

  depends_on = [module.eks]
}

module "clickhouse_cluster" {
  source = "./clickhouse-cluster"

  clickhouse_cluster_name          = var.clickhouse_cluster_name
  clickhouse_cluster_namespace     = var.clickhouse_cluster_namespace
  clickhouse_cluster_password      = var.clickhouse_cluster_password
  clickhouse_cluster_user          = var.clickhouse_cluster_user
  clickhouse_cluster_manifest_path = var.clickhouse_cluster_manifest_path

  cluster_token                 = module.eks.cluster_token
  cluster_endpoint              = module.eks.cluster_endpoint
  cluster_certificate_authority = base64decode(module.eks.cluster_certificate_authority)

  depends_on = [module.eks, module.clickhouse_operator]
}
