resource "kubernetes_namespace" "zookeeper" {
  metadata {
    name = "zookeeper"
  }
}

resource "kubernetes_service" "zookeeper" {
  depends_on = [kubernetes_namespace.zookeeper]

  metadata {
    namespace = kubernetes_namespace.zookeeper.metadata[0].name
    name      = "zookeeper"

    labels = {
      app = "zookeeper"
    }
  }

  spec {
    port {
      port = 2181
      name = "client"
    }

    port {
      port = 7000
      name = "prometheus"
    }

    selector = {
      app  = "zookeeper"
      what = "node"
    }
  }
}

resource "kubernetes_service" "zookeepers" {
  depends_on = [kubernetes_namespace.zookeeper]
  metadata {
    name      = "zookeepers"
    namespace = kubernetes_namespace.zookeeper.metadata[0].name

    labels = {
      app = "zookeeper"
    }
  }

  spec {
    port {
      port = 2888
      name = "server"
    }

    port {
      port = 3888
      name = "leader-election"
    }

    cluster_ip = "None"

    selector = {
      app  = "zookeeper"
      what = "node"
    }
  }
}

# resource "kubernetes_pod_disruption_budget" "zookeeper_pdb" {
#   metadata {
#     namespace = kubernetes_namespace.zookeeper.metadata[0].name
#     name      = "zookeeper-pod-disruption-budget"
#   }

#   spec {
#     max_unavailable = 1

#     selector {
#       match_labels = {
#         app = "zookeeper"
#       }
#     }
#   }
# }

resource "kubernetes_stateful_set" "zookeeper" {
  depends_on = [kubernetes_namespace.zookeeper]
  metadata {
    name      = "zookeeper"
    namespace = kubernetes_namespace.zookeeper.metadata[0].name

    labels = {
      app = "zookeeper"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "zookeeper"
      }
    }

    service_name          = "zookeepers"
    pod_management_policy = "OrderedReady"
    update_strategy {
      type = "RollingUpdate"
    }

    template {
      metadata {
        labels = {
          app  = "zookeeper"
          what = "node"
        }
        annotations = {
          "prometheus.io/port"   = "7000"
          "prometheus.io/scrape" = "true"
        }
      }

      spec {
        security_context {
          run_as_user = 1000
          fs_group    = 1000
        }

        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              label_selector {
                match_expressions {
                  key      = "app"
                  operator = "In"
                  values   = ["zookeeper"]
                }
              }
              topology_key = "kubernetes.io/hostname"
            }
          }
        }

        container {
          name              = "kubernetes-zookeeper"
          image             = "docker.io/zookeeper:3.8.3"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 2181
            name           = "client"
          }

          port {
            container_port = 2888
            name           = "server"
          }

          port {
            container_port = 3888
            name           = "leader-election"
          }

          port {
            container_port = 7000
            name           = "prometheus"
          }

          resources {
            requests = {
              memory = "512M"
              cpu    = "1"
            }

            limits = {
              memory = "4Gi"
              cpu    = "2"
            }
          }

          env {
            name  = "SERVERS"
            value = "1"
          }

          command = [
            "bash",
            "-x",
            "-c",
            file("${path.module}/scripts/1.sh")
          ]

          readiness_probe {
            exec {
              command = [
                "bash",
                "-c",
                file("${path.module}/scripts/2.sh")
              ]
            }

            initial_delay_seconds = 10
            period_seconds        = 60
            timeout_seconds       = 60
          }

          liveness_probe {
            exec {
              command = [
                "bash",
                "-xc",
                <<EOF
                date && OK=$(exec 3<>/dev/tcp/127.0.0.1/2181 ; printf "ruok" >&3 ; IFS=; tee <&3; exec 3<&- ;); if [[ "$OK" == "imok" ]]; then exit 0; else exit 1; fi
                EOF
              ]
            }

            initial_delay_seconds = 10
            period_seconds        = 30
            timeout_seconds       = 5
          }

          volume_mount {
            name       = "datadir-volume"
            mount_path = "/var/lib/zookeeper"
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "datadir-volume"
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "25Gi"
          }
        }
      }
    }
  }
}
