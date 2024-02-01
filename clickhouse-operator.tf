locals {
  manifest   = "${path.module}/${var.clickhouse_operator_path}"
  kubeconfig = <<-EOT
    apiVersion: v1
    clusters:
    - cluster:
        server: ${data.aws_eks_cluster.this.endpoint}
        certificate-authority-data: ${data.aws_eks_cluster.this.certificate_authority.0.data}
      name: ${data.aws_eks_cluster.this.arn}
    contexts:
    - context:
        cluster: ${data.aws_eks_cluster.this.arn}
        user: ${data.aws_eks_cluster.this.arn}
      name: ${data.aws_eks_cluster.this.arn}
    current-context: ${data.aws_eks_cluster.this.arn}
    kind: Config
    preferences: {}
    users:
    - name: ${data.aws_eks_cluster.this.arn}
      user:
        exec:
          apiVersion: client.authentication.k8s.io/v1beta1
          command: aws
          args:
          - --region
          - ${var.region}
          - eks
          - get-token
          - --cluster-name
          - ${var.cluster_name}
          - --output
          - json
  EOT
}

resource "null_resource" "install_clickhouse_operator" {
  depends_on = [aws_eks_cluster.this]

  triggers = {
    kubeconfig = local.kubeconfig
    manifest   = file(local.manifest)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "bash ${path.module/install-clickhouse-operator.sh} '${local.kubeconfig}' '${local.manifest}' '${var.confirm_operator_manifest_changes}'"
  }
}
