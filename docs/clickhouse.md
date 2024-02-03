# Altinity ClickHouse Operator & ClickHouse Cluster

This Terraform module orchestrates the setup and deployment of the [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator) on an AWS EKS cluster. The module is designed to ensure a streamlined and automated process for managing ClickHouse databases within a Kubernetes environment, specifically on AWS EKS.

### Random Password Generation
- `resource "random_password" "this"`: Creates a random password for ClickHouse clusters when a predefined password is not provided. The length is set to 22 characters without special characters. This resource includes a lifecycle policy to ignore changes, maintaining the password across apply operations.

### Operator Deployment
- `resource "kubectl_manifest" "clickhouse_operator"`: Applies each manifest required for the ClickHouse operator, including CRD, Service, ConfigMap, and Deployment. It iterates over the `local.operator_manifests`, applying each manifest separately.

### Namespace Creation
- `resource "kubernetes_namespace" "clickhouse"`: Establishes a dedicated Kubernetes namespace for the ClickHouse cluster. It depends on the successful application of the ClickHouse operator manifests.

### ClickHouse Cluster Creation
- `resource "kubectl_manifest" "clickhouse_cluster"`: Deploys a ClickHouse cluster by creating a new ClickHouseInstallation custom resource. This resource depends on the ClickHouse namespace and injects variables like cluster name, namespace, user, and the generated or provided password.

### Service Data Retrieval
- `data "kubernetes_service" "clickhouse_load_balancer"`: Retrieves details about the ClickHouse service, particularly the load balancer configuration. It depends on the successful deployment of the ClickHouse cluster.

> 💡 **TL;DR**: The Terraform module for the Altinity ClickHouse Operator simplifies and automates the deployment on AWS EKS. It manages dependencies, automates password generation, applies necessary Kubernetes manifests, and establishes the necessary resources for a robust ClickHouse deployment. The module is designed for ease of use, maintainability, and security in a cloud-native environment.
