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

resource "kubernetes_pod_disruption_budget_v1" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  spec {
    selector {
      match_labels = {
        "app"                        = "ebs-csi-controller"
        "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
        "app.kubernetes.io/instance" = "aws-ebs-csi-driver"
      }
    }

    max_unavailable = 1
  }
}

resource "kubernetes_service_account" "ebs_csi_controller_sa" {
  metadata {
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ebs_csi_driver_role.arn
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_service_account" "ebs_csi_node_sa" {
  metadata {
    name      = "ebs-csi-node-sa"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "ebs_external_attacher_role" {
  metadata {
    name = "ebs-external-attacher-role"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["csi.storage.k8s.io"]
    resources  = ["csinodeinfos"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments/status"]
    verbs      = ["patch"]
  }
}

resource "kubernetes_cluster_role" "ebs_csi_node_role" {
  metadata {
    name = "ebs-csi-node-role"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "patch"]
  }
}

resource "kubernetes_cluster_role" "ebs_external_provisioner_role" {
  metadata {
    name = "ebs-external-provisioner-role"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch", "update"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshots"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csinodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["volumeattachments"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role" "ebs_external_resizer_role" {
  metadata {
    name = "ebs-external-resizer-role"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  # Uncomment the following rule if your plugin requires secrets for provisioning
  # rule {
  #   api_groups = [""]
  #   resources  = ["secrets"]
  #   verbs      = ["get", "list", "watch"]
  # }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["persistentvolumeclaims/status"]
    verbs      = ["update", "patch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list", "watch", "create", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role" "ebs_external_snapshotter_role" {
  metadata {
    name = "ebs-external-snapshotter-role"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list", "watch", "create", "update", "patch"]
  }

  # Uncomment if secrets are needed
  # rule {
  #   api_groups = [""]
  #   resources  = ["secrets"]
  #   verbs      = ["get", "list"]
  # }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents"]
    verbs      = ["create", "get", "list", "watch", "update", "delete", "patch"]
  }

  rule {
    api_groups = ["snapshot.storage.k8s.io"]
    resources  = ["volumesnapshotcontents/status"]
    verbs      = ["update"]
  }
}

resource "kubernetes_cluster_role_binding" "ebs_csi_attacher_binding" {
  metadata {
    name = "ebs-csi-attacher-binding"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "ebs-external-attacher-role"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "ebs_csi_node_getter_binding" {
  metadata {
    name = "ebs-csi-node-getter-binding"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "ebs-csi-node-role"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-node-sa"
    namespace = "kube-system"
  }
}


resource "kubernetes_cluster_role_binding" "ebs_csi_provisioner_binding" {
  metadata {
    name = "ebs-csi-provisioner-binding"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "ebs-external-provisioner-role"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "ebs_csi_resizer_binding" {
  metadata {
    name = "ebs-csi-resizer-binding"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "ebs-external-resizer-role"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "ebs_csi_snapshotter_binding" {
  metadata {
    name = "ebs-csi-snapshotter-binding"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "ebs-external-snapshotter-role"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
}

resource "kubernetes_role" "ebs_csi_leases_role" {
  metadata {
    name      = "ebs-csi-leases-role"
    namespace = "kube-system"
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "watch", "list", "delete", "update", "create"]
  }
}


resource "kubernetes_role_binding" "ebs_csi_leases_rolebinding" {
  metadata {
    name      = "ebs-csi-leases-rolebinding"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  role_ref {
    kind      = "Role"
    name      = "ebs-csi-leases-role"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "ebs-csi-controller-sa"
    namespace = "kube-system"
  }
}


resource "kubernetes_daemonset" "ebs_csi_node" {
  metadata {
    name      = "ebs-csi-node"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  spec {
    selector {
      match_labels = {
        "app"                        = "ebs-csi-node"
        "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
        "app.kubernetes.io/instance" = "aws-ebs-csi-driver"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "10%"
      }
    }

    template {
      metadata {
        labels = {
          "app"                          = "ebs-csi-node"
          "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
          "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
          "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
          "app.kubernetes.io/version"    = "1.20.0"
          "app.kubernetes.io/component"  = "csi-driver"
          "app.kubernetes.io/managed-by" = "Helm"
        }
      }

      spec {
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name = "ebs-csi-node-sa"
        priority_class_name  = "system-node-critical"

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate"]
                }
              }
            }
          }
        }

        toleration {
          operator = "Exists"
        }

        security_context {
          fs_group        = 0
          run_as_group    = 0
          run_as_non_root = false
          run_as_user     = 0
        }

        container {
          name              = "ebs-plugin"
          image             = "public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver:v1.20.0"
          image_pull_policy = "IfNotPresent"

          args = [
            "node",
            "--endpoint=$(CSI_ENDPOINT)",
            "--logging-format=text",
            "--v=2"
          ]

          env {
            name  = "CSI_ENDPOINT"
            value = "unix:/csi/csi.sock"
          }

          env {
            name = "CSI_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name  = "AWS_REGION"
            value = local.region
          }

          volume_mount {
            name              = "kubelet-dir"
            mount_path        = "/var/lib/kubelet"
            mount_propagation = "Bidirectional"
          }

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/csi"
          }

          volume_mount {
            name       = "device-dir"
            mount_path = "/dev"
          }

          port {
            name           = "healthz"
            container_port = 9808
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 3
            period_seconds        = 10
            failure_threshold     = 5
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            privileged                = true
            read_only_root_filesystem = true
          }
        }

        container {
          name              = "node-driver-registrar"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/node-driver-registrar:v2.8.0-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=$(ADDRESS)",
            "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)",
            "--v=2"
          ]

          env {
            name  = "ADDRESS"
            value = "/csi/csi.sock"
          }

          env {
            name  = "DRIVER_REG_SOCK_PATH"
            value = "/var/lib/kubelet/plugins/ebs.csi.aws.com/csi.sock"
          }

          liveness_probe {
            initial_delay_seconds = 30
            timeout_seconds       = 15
            period_seconds        = 90

            exec {
              command = [
                "/csi-node-driver-registrar",
                "--kubelet-registration-path=$(DRIVER_REG_SOCK_PATH)",
                "--mode=kubelet-registration-probe"
              ]
            }
          }

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/csi"
          }

          volume_mount {
            name       = "registration-dir"
            mount_path = "/registration"
          }

          volume_mount {
            name       = "probe-dir"
            mount_path = "/var/lib/kubelet/plugins/ebs.csi.aws.com/"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "20Mi"
            }

            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }



          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        container {
          name              = "liveness-probe"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe:v2.10.0-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=/csi/csi.sock"
          ]

          volume_mount {
            name       = "plugin-dir"
            mount_path = "/csi"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "20Mi"
            }

            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        volume {
          name = "kubelet-dir"
          host_path {
            path = "/var/lib/kubelet"
            type = "Directory"
          }
        }

        volume {
          name = "plugin-dir"
          host_path {
            path = "/var/lib/kubelet/plugins/ebs.csi.aws.com/"
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "registration-dir"
          host_path {
            path = "/var/lib/kubelet/plugins_registry/"
            type = "Directory"
          }
        }

        volume {
          name = "device-dir"
          host_path {
            path = "/dev"
            type = "Directory"
          }
        }

        volume {
          name = "probe-dir"
          empty_dir {}
        }
      }
    }
  }
}


resource "kubernetes_deployment" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        "app"                        = "ebs-csi-controller"
        "app.kubernetes.io/name"     = "aws-ebs-csi-driver"
        "app.kubernetes.io/instance" = "aws-ebs-csi-driver"
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = 1
      }
    }

    template {
      metadata {
        labels = {
          "app"                          = "ebs-csi-controller"
          "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
          "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
          "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
          "app.kubernetes.io/version"    = "1.20.0"
          "app.kubernetes.io/component"  = "csi-driver"
          "app.kubernetes.io/managed-by" = "Helm"
        }
      }

      spec {
        service_account_name = "ebs-csi-controller-sa"
        priority_class_name  = "system-cluster-critical"
        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        affinity {
          node_affinity {
            preferred_during_scheduling_ignored_during_execution {
              preference {
                match_expressions {
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate"]
                }
              }
              weight = 1
            }
          }

          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app"
                    operator = "In"
                    values   = ["ebs-csi-controller"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
              weight = 100
            }
          }
        }

        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }

        toleration {
          effect             = "NoExecute"
          operator           = "Exists"
          toleration_seconds = 300
        }

        security_context {
          fs_group        = 1000
          run_as_group    = 1000
          run_as_non_root = true
          run_as_user     = 1000
        }

        container {
          name              = "ebs-plugin"
          image             = "public.ecr.aws/ebs-csi-driver/aws-ebs-csi-driver:v1.20.0"
          image_pull_policy = "IfNotPresent"
          args = [
            "controller",
            "--endpoint=$(CSI_ENDPOINT)",
            "--extra-tags=${join(",", [for k, v in local.tags : "${k}=${v}"])}",
            "--k8s-tag-cluster-id=${local.cluster_name}",
            "--logging-format=text",
            "--user-agent-extra=helm",
            "--v=5"
          ]
          env {
            name  = "CSI_ENDPOINT"
            value = "unix:///var/lib/csi/sockets/pluginproxy/csi.sock"
          }
          env {
            name = "CSI_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          env {
            name = "AWS_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                name     = "aws-secret"
                key      = "key_id"
                optional = true
              }
            }
          }
          env {
            name = "AWS_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name     = "aws-secret"
                key      = "access_key"
                optional = true
              }
            }
          }
          env {
            name = "AWS_EC2_ENDPOINT"
            value_from {
              config_map_key_ref {
                name     = "aws-meta"
                key      = "endpoint"
                optional = true
              }
            }
          }
          volume_mount {
            name       = "socket-dir"
            mount_path = "/var/lib/csi/sockets/pluginproxy/"
          }
          port {
            name           = "healthz"
            container_port = 9808
            protocol       = "TCP"
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 3
            period_seconds        = 10
            failure_threshold     = 5
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = "healthz"
            }
            initial_delay_seconds = 10
            timeout_seconds       = 3
            period_seconds        = 10
            failure_threshold     = 5
          }
          resources {
            limits = {
              cpu    = "200m"
              memory = "200Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }
          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        container {
          name              = "csi-provisioner"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/external-provisioner:v3.5.0-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=$(ADDRESS)",
            "--v=2",
            "--feature-gates=Topology=true",
            "--extra-create-metadata",
            "--leader-election=true",
            "--default-fstype=ext4"
          ]

          env {
            name  = "ADDRESS"
            value = "/var/lib/csi/sockets/pluginproxy/csi.sock"
          }

          volume_mount {
            name       = "socket-dir"
            mount_path = "/var/lib/csi/sockets/pluginproxy/"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "20Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        container {
          name              = "csi-attacher"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/external-attacher:v4.3.0-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=$(ADDRESS)",
            "--v=2",
            "--leader-election=true"
          ]

          env {
            name  = "ADDRESS"
            value = "/var/lib/csi/sockets/pluginproxy/csi.sock"
          }

          volume_mount {
            name       = "socket-dir"
            mount_path = "/var/lib/csi/sockets/pluginproxy/"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "20Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        container {
          name              = "csi-snapshotter"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/external-snapshotter/csi-snapshotter:v6.2.1-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=$(ADDRESS)",
            "--leader-election=true",
            "--extra-create-metadata"
          ]

          env {
            name  = "ADDRESS"
            value = "/var/lib/csi/sockets/pluginproxy/csi.sock"
          }

          volume_mount {
            name       = "socket-dir"
            mount_path = "/var/lib/csi/sockets/pluginproxy/"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "20Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        container {
          name              = "csi-resizer"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/external-resizer:v1.8.0-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=$(ADDRESS)",
            "--v=2",
            "--handle-volume-inuse-error=false",
            "--leader-election=true"
          ]

          env {
            name  = "ADDRESS"
            value = "/var/lib/csi/sockets/pluginproxy/csi.sock"
          }

          volume_mount {
            name       = "socket-dir"
            mount_path = "/var/lib/csi/sockets/pluginproxy/"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "50Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        container {
          name              = "liveness-probe"
          image             = "public.ecr.aws/eks-distro/kubernetes-csi/livenessprobe:v2.10.0-eks-1-27-3"
          image_pull_policy = "IfNotPresent"

          args = [
            "--csi-address=/csi/csi.sock"
          ]

          volume_mount {
            name       = "socket-dir"
            mount_path = "/csi"
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "20Mi"
            }
            requests = {
              cpu    = "5m"
              memory = "10Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        volume {
          name = "socket-dir"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_csi_driver_v1" "ebs_csi_aws_com" {
  metadata {
    name = "ebs.csi.aws.com"
    labels = {
      "app.kubernetes.io/name"       = "aws-ebs-csi-driver"
      "app.kubernetes.io/instance"   = "aws-ebs-csi-driver"
      "helm.sh/chart"                = "aws-ebs-csi-driver-2.20.0"
      "app.kubernetes.io/version"    = "1.20.0"
      "app.kubernetes.io/component"  = "csi-driver"
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  spec {
    attach_required   = true
    pod_info_on_mount = false
  }
}

resource "kubernetes_storage_class" "gp3" {
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

