module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = aws_iam_role.ebs_csi_driver_role.arn
    }
  }

  enable_cluster_autoscaler = true
  cluster_autoscaler = {
    timeout = "300"
    values = [templatefile("${path.module}/helm/cluster-autoscaler.yaml.tpl", {
      aws_region         = var.region,
      eks_cluster_id     = var.cluster_name,
      autoscaler_version = var.image_tag,
      role_arn           = aws_iam_role.cluster_autoscaler.arn
    })]
  }
}

resource "kubernetes_storage_class" "gp3-encrypted" {
  depends_on = [module.eks_blueprints_addons]

  metadata {
    name = "gp3-encrypted"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    encrypted = "true"
    fsType    = "ext4"
    type      = "gp3"
  }

  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
}
