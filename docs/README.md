# Terraform Module for EKS ClickHouse Cluster

This Terraform module automates the deployment of a [ClickHouse](https://clickhouse.com) database cluster on [Amazon EKS](https://aws.amazon.com/eks/) (Elastic Kubernetes Service). It is designed to create and configure the necessary resources for a robust and scalable ClickHouse deployment.

## Key Features

This architecture is designed to provide a scalable, secure, and efficient environment for running a ClickHouse database on Kubernetes within AWS EKS. The focus on autoscaling, storage management, and proper IAM configurations highlights its suitability for enterprise-level deployments using the following resources:

- **IAM Roles and Policies**: There are several IAM roles and policies created for different purposes, such as the EKS cluster role, node role, and a specific role for the EBS CSI driver. These roles and policies ensure appropriate permissions for the cluster to interact with other AWS services.

- **EKS Cluster**: The script sets up an AWS EKS cluster (`aws_eks_cluster.this`). It specifies the EKS version, role ARN, and VPC configuration, ensuring the cluster is isolated within a VPC.

- **Node Groups**: Multiple EKS node groups (`aws_eks_node_group.this`) are created, each configured with specific instance types and subnet associations. This setup allows for a diversified and scalable node environment.

- **Kubernetes Autoscaler**: A Kubernetes deployment is configured for the cluster autoscaler. This deployment ensures the cluster can scale its nodes based on the workload demands automatically.

- **EBS CSI Driver**: The script includes setup for the EBS CSI driver, which is crucial for managing storage volumes in AWS. This includes roles, policy attachments, and Kubernetes configurations (like `kubernetes_csi_driver_v1`) for the CSI driver to function correctly.

- **Networking**: The script includes configurations for VPCs, subnets, route tables, and internet gateways, which are essential for the network infrastructure of the EKS cluster.

- **Storage and Resource Access**: Kubernetes roles, role bindings, and service accounts are defined for different components, particularly for the EBS CSI driver, ensuring the right permissions for accessing and managing resources.

## Architecture:

> ADD DIAGRAM HERE

- [VPC & Subnets](./vpc.md)
- [EKS Cluster & Node Groups](./eks.md)
- [K8S Autoscaler](./autoscaler.md)
- [EBS & CSI Driver](./ebs.md)

## Prerequisites

- AWS Account with appropriate permissions
- Terraform installed
- Basic knowledge of Kubernetes and AWS services

## Usage

```hcl
provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
}

module "eks_clickhouse" {
  source  = "github.com/Altinity/terraform-eks-clickhouse"

  cluster_name = "clickhouse-cluster"
  region       = "us-east-1"
  cidr         = "10.0.0.0/16"
  subnets      = [
    { cidr_block = "10.0.1.0/24", az = "us-east-1a" },
    { cidr_block = "10.0.2.0/24", az = "us-east-1b" },
    { cidr_block = "10.0.3.0/24", az = "us-east-1c" }
  ]

  node_pools_config = {
    scaling_config = {
      desired_size = 2
      max_size     = 10
      min_size     = 0
    }

    disk_size      = 20
    instance_types = ["m5.large"]
  }
}
```

> ⚠️ This module will create a Node Pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different Node Pools.

👉 Check [here](spec.md) the complete terraform specification for this module.