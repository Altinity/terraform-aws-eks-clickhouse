resource "aws_iam_policy" "cluster_autoscaler" {
  name   = "eks-cluster-autoscaler"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeImages",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "cluster_autoscaler" {
  name               = "eks-cluster-autoscaler"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${local.account_id}:oidc-provider/${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:cluster-autoscaler"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

resource "local_file" "autoscaler_manifest" {
  content = templatefile("${path.module}/cluster-autoscaler.tpl", {
    role_arn     = aws_iam_role.cluster_autoscaler.arn
    cluster_name = aws_eks_cluster.this.name
    image        = "v1.26.1"
    replicas     = 2
  })

  filename = "${path.module}/cluster-autoscaler.yaml"
}

resource "null_resource" "cluster_autoscaler" {
  depends_on = [aws_eks_cluster.this, local_file.autoscaler_manifest]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/cluster-autoscaler.yaml"
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
