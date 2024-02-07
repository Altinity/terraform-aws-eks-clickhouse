# Altinity ClickHouse Operator & ClickHouse Cluster Deployment with Zookeeper Integration on AWS EKS

This Terraform module orchestrates the deployment of the [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator) on an AWS EKS cluster and sets up a ClickHouse cluster with Zookeeper integration. It is designed to streamline the process of managing ClickHouse databases within a Kubernetes environment, emphasizing automation and ease of use on AWS EKS.

### Random Password Generation
- `resource "random_password" "this"`: Generates a random password for the ClickHouse cluster if a predefined one is not supplied. The password has 22 characters, excluding special characters, and includes a lifecycle policy to disregard changes, preserving the password across Terraform apply operations.

### Altinity ClickHouse Operator
- **Operator Deployment**: Utilizes `resource "kubectl_manifest" "clickhouse_operator"` to apply the necessary manifests (CRD, Service, ConfigMap, Deployment) for the ClickHouse operator. It iterates over `local.clickhouse_operator_manifests`, applying each manifest individually.

### Zookeeper Cluster Deployment
- **Zookeeper Cluster**: The `resource "kubectl_manifest" "zookeeper_cluster"` deploys the Zookeeper cluster necessary for ClickHouse, iterating over `local.zookeeper_cluster_manifests` to apply each manifest. This setup is critical for enabling distributed ClickHouse configurations.

### Namespace Creation
- **ClickHouse Namespace**: `resource "kubernetes_namespace" "clickhouse"` creates a Kubernetes namespace dedicated to the ClickHouse cluster, ensuring isolation and organization.
- **Zookeeper Namespace**: Similarly, `resource "kubernetes_namespace" "zookeeper"` establishes a separate namespace for the Zookeeper cluster, maintaining a clear separation of concerns and operational clarity.

### ClickHouse Cluster Creation
- `resource "kubectl_manifest" "clickhouse_cluster"`: Deploys the ClickHouse cluster by provisioning a new ClickHouseInstallation custom resource, incorporating variables such as cluster name, namespace, user, and either a generated or provided password. This resource incorporates the Zookeeper namespace for proper cluster coordination.

### Service Data Retrieval
- `data "kubernetes_service" "clickhouse_load_balancer"`: Fetches details about the ClickHouse service, focusing on the load balancer setup, to facilitate external access. This data source is contingent on the successful rollout of the ClickHouse cluster.

> 💡 **TL;DR**: This Terraform module automates the deployment of the Altinity ClickHouse Operator and a ClickHouse cluster with Zookeeper on K8S. It meticulously manages dependencies, streamlines password generation, and applies necessary Kubernetes manifests, culminating in a robust, maintainable, and secure setup for cloud-native database management. The configuration leverages local values for parsing YAML manifests of both the ClickHouse operator and the Zookeeper cluster, ensuring a modular and dynamic deployment process. By integrating Zookeeper, the module supports high-availability and distributed ClickHouse configurations, enhancing the resilience and scalability of the database infrastructure.
