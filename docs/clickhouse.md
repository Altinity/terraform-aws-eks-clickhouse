# Altinity Kubernetes Operator for ClickHouse® & ClickHouse Cluster Deployment on AWS EKS

> **TL;DR**: This Terraform module automates the deployment of the Altinity Kubernetes operator for ClickHouse® and a ClickHouse cluster with ClickHouse Keeper on K8s. It manages Helm chart releases, password generation, and namespace creation, providing a robust and maintainable setup for cloud-native database management.

This Terraform module orchestrates the deployment of the [Altinity Kubernetes operator for ClickHouse](https://github.com/Altinity/clickhouse-operator) on an AWS EKS cluster and sets up a ClickHouse cluster with ClickHouse Keeper integration. It is designed to streamline the process of managing ClickHouse databases within a Kubernetes environment, emphasizing automation and ease of use on AWS EKS.

### Random Password Generation
- `resource "random_password" "this"`: Generates a random password for the ClickHouse cluster if a predefined one is not supplied. The password has 22 characters, excluding special characters, and includes a lifecycle policy to disregard changes, preserving the password across Terraform `apply` operations.

### Altinity Kubernetes Operator for ClickHouse
- **Operator Deployment**: Uses `helm_release "altinity_clickhouse_operator"` to deploy the Altinity ClickHouse operator from the official Helm chart repository. The operator manages the lifecycle of ClickHouse clusters, including scaling, configuration, and upgrades.

### ClickHouse Keeper Deployment
- **ClickHouse Keeper**: Deployed via `helm_release "clickhouse_keeper"` using the Altinity Helm charts. ClickHouse Keeper provides cluster coordination (replacing ZooKeeper) and is deployed in the same namespace as the ClickHouse cluster.

### Namespace Creation
- **ClickHouse Namespace**: `resource "kubernetes_namespace" "clickhouse"` creates a Kubernetes namespace dedicated to the ClickHouse cluster and Keeper, ensuring isolation and organization.

### ClickHouse Cluster Creation
- `helm_release "clickhouse_cluster"`: Deploys the ClickHouse cluster using the Altinity Helm chart, with configuration provided via a values template that includes cluster name, availability zones, instance type for node selection, service type, user credentials, and storage class.

### Service Data Retrieval
- `data "kubernetes_service" "clickhouse_load_balancer"`: Fetches details about the ClickHouse service load balancer when enabled, to expose the cluster URL as a Terraform output. This is gated behind the `clickhouse_cluster_enable_loadbalancer` variable.
