# Terraform AWS EKS ClickHouse® Module

<div align="right">
  <img src="https://altinity.com/wp-content/uploads/2022/05/logo_horizontal_blue_white.svg" alt="Altinity" width="120">
</div>

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-blue.svg)](https://registry.terraform.io/modules/Altinity/eks-clickhouse/aws/latest)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Issues](https://img.shields.io/github/issues/altinity/terraform-aws-eks-clickhouse.svg)](https://github.com/altinity/terraform-aws-eks-clickhouse/issues)
[![Documentation](https://img.shields.io/badge/-documentation-blue)](https://github.com/Altinity/terraform-aws-eks-clickhouse/tree/master/docs)
<a href="https://join.slack.com/t/altinitydbworkspace/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ">
  <img src="https://img.shields.io/static/v1?logo=slack&logoColor=959DA5&label=Slack&labelColor=333a41&message=join%20conversation&color=3AC358" alt="AltinityDB Slack" />
</a>

Terraform module for creating EKS clusters optimized for ClickHouse® with EBS and autoscaling. This module provides a complete solution for deploying production-ready ClickHouse clusters on AWS EKS, including the Altinity Kubernetes Operator for ClickHouse and a fully working ClickHouse cluster.

For detailed architecture and configuration options, see the [documentation](https://github.com/Altinity/terraform-aws-eks-clickhouse/tree/master/docs).

## Prerequisites

Before using this module, ensure you have:

1. **Terraform** >= 1.5
2. **AWS CLI** configured with appropriate credentials
3. **kubectl** for Kubernetes cluster management
4. **AWS account** with permissions to create EKS clusters, VPCs, and related resources

## Usage
###  Compatibility Notice
⚠️ This module is not yet compatible with the latest versions of the following providers:
  - AWS Provider v6.x.x
  - Helm Provider v3.x.x

> Please use supported versions until compatibility updates are released. Contributions are welcome 🙌


### Basic Setup

This module creates a complete EKS cluster optimized for ClickHouse workloads. The sample configuration below will create Node Pools for each combination of instance type and subnet. For example, with 3 subnets and 2 instance types, this module will create 6 different Node Pools.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

locals {
  region = "us-east-1"
}

provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
  region = local.region
}

module "eks_clickhouse" {
  source  = "github.com/Altinity/terraform-aws-eks-clickhouse"

  install_clickhouse_operator = true
  install_clickhouse_cluster  = true

  # Set to true if you want to use a public load balancer (and expose ports to the public Internet)
  clickhouse_cluster_enable_loadbalancer = false

  eks_cluster_name = "clickhouse-cluster"
  eks_region       = local.region
  eks_cidr         = "10.0.0.0/16"

  eks_availability_zones = [
    "${local.region}a",
    "${local.region}b",
    "${local.region}c"
  ]
  eks_private_cidr = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
  eks_public_cidr = [
    "10.0.101.0/24",
    "10.0.102.0/24",
    "10.0.103.0/24"
  ]

  eks_node_pools = [
    {
      name          = "clickhouse"
      instance_type = "m6i.large"
      desired_size  = 0
      max_size      = 10
      min_size      = 0
      zones         = ["${local.region}a", "${local.region}b", "${local.region}c"]
    },
    {
      name          = "system"
      instance_type = "t3.large"
      desired_size  = 1
      max_size      = 10
      min_size      = 0
      zones         = ["${local.region}a"]
    }
  ]

  eks_tags = {
    CreatedBy = "mr-robot"
  }
}
```

> ⚠️ The instance type of `eks_node_pools` at index `0` will be used for setting up the clickhouse cluster replicas.

## Examples

For comprehensive examples covering different configurations and use cases, see the [examples directory](examples/):

- **Default**: Complete EKS cluster with ClickHouse operator and cluster
- **EKS Cluster Only**: Just the EKS infrastructure without ClickHouse components
- **Public Load Balancer**: Configuration with external access via load balancer
- **Public Subnets Only**: Simplified networking setup for development

### Deployment

Execute the following commands to initialize and apply the Terraform module:

```sh
terraform init
terraform apply
```

> ⏱️ Setting up the EKS cluster and ClickHouse database takes 10-30 minutes depending on cluster load and resource availability.

### Accessing Your ClickHouse Database

1. **Update kubeconfig** with your new EKS cluster credentials:
   ```sh
   aws eks update-kubeconfig --region us-east-1 --name clickhouse-cluster
   ```

2. **Connect to ClickHouse** using kubectl:
   ```sh
   kubectl exec -it chi-eks-dev-0-0-0 -n clickhouse -- clickhouse-client
   ```

### Cleanup

To destroy the cluster:

1. **Delete ClickHouse clusters** first:
   ```sh
   kubectl delete chi --all --all-namespaces
   ```

2. **Destroy infrastructure**:
   ```sh
   terraform destroy
   ```

## Modules

This module is composed of several sub-modules that work together to create a complete ClickHouse environment:

| Module | Description |
|--------|-------------|
| `eks` | Creates the EKS cluster with optimized node groups and networking |
| `clickhouse-operator` | Installs the Altinity Kubernetes Operator for ClickHouse |
| `clickhouse-cluster` | Deploys a production-ready ClickHouse cluster |

## Configuration

Key configuration options include:

- **EKS Settings**: Cluster name, region, VPC CIDR, availability zones
- **Node Pools**: Instance types, scaling configuration, zone distribution
- **ClickHouse**: Operator installation, cluster deployment, load balancer configuration
- **Networking**: Public/private subnets, security groups, load balancer settings

For detailed configuration options, see the [Terraform Registry documentation](https://registry.terraform.io/modules/Altinity/eks-clickhouse/aws/latest).

## Troubleshooting

- **Terraform timeouts**: EKS cluster creation can take 15-30 minutes. If operations timeout, try running them again.
- **Node group scaling issues**: Ensure your AWS account has sufficient EC2 limits for the desired instance types.
- **ClickHouse connection problems**: Verify the cluster is fully deployed using `kubectl get chi -n clickhouse`.
- **Load balancer access**: Check security group rules and ensure proper networking configuration.

### Need Help?

If you encounter issues not covered above, please [create an issue](https://github.com/altinity/terraform-aws-eks-clickhouse/issues) with detailed information about your problem.

## Contributing

Contributions are welcome! Please submit a Pull Request or open an issue for major changes. When contributing:

1. Fork the repository
2. Create a feature branch
3. Make your changes with appropriate tests
4. Submit a pull request with a clear description

## More Information and Commercial Support

Altinity is the maintainer of this project. Altinity offers a range of services related to ClickHouse and analytic applications on Kubernetes:

- **[Official Website](https://altinity.com/)** - Get a high level overview of Altinity and our offerings
- **[Altinity.Cloud](https://altinity.com/cloud-database/)** - Run ClickHouse in our cloud or yours
- **[Enterprise Support](https://altinity.com/support/)** - Get Enterprise-class support for ClickHouse
- **[Community Slack](https://altinitydbworkspace.slack.com/join/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ)** - Talk directly with ClickHouse users and Altinity devs
- **[Contact Us](https://hubs.la/Q020sH3Z0)** - Contact Altinity with your questions or issues

## License

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2024 Altinity, Inc.
