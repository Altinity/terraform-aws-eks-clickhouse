data "aws_iam_policy_document" "ebs_csi_driver_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  name               = "${local.cluster_name}-eks-ebs-csi-driver"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi_driver_policy_attachment" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "local_file" "ebs_csi_driver_manifest" {
  content = templatefile("${path.module}/ebs_csi_driver_manifest.tpl", {
    role_arn   = aws_iam_role.ebs_csi_driver_role.arn
    tags       = join(",", [for k, v in local.tags : "${k}=${v}"])
    cluster_id = aws_eks_cluster.this.name
  })

  filename = "${path.module}/ebs_csi_driver_manifest.yaml"
}

resource "null_resource" "update_kubeconfig" {
  depends_on = [aws_eks_cluster.this]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${local.region}"
  }

  triggers = {
    cluster_name     = aws_eks_cluster.this.name
    cluster_endpoint = aws_eks_cluster.this.endpoint
  }
}

resource "null_resource" "apply_ebs_csi_driver" {
  depends_on = [aws_eks_cluster.this, local_file.ebs_csi_driver_manifest, null_resource.update_kubeconfig]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.ebs_csi_driver_manifest.filename}"
  }

  triggers = {
    manifest   = local_file.ebs_csi_driver_manifest.content
  }
}

// DO we need this?
resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type   = "gp3"
    fsType = "ext4" # Optional. The filesystem type to use (ext3, ext4, xfs...)
  }

  allow_volume_expansion = true # Optional. Allow volume to be expanded
}