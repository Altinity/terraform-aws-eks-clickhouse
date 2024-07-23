**🚨 This module is still under development and not fully ready for production use; use it at your own risk.**

# terraform-aws-eks-clickhouse

[![License](http://img.shields.io/:license-apache%202.0-brightgreen.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![issues](https://img.shields.io/github/issues/altinity/terraform-aws-eks-clickhouse.svg)](https://github.com/altinity/terraform-aws-eks-clickhouse/issues)
<a href="https://join.slack.com/t/altinitydbworkspace/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ">
  <img src="https://img.shields.io/static/v1?logo=slack&logoColor=959DA5&label=Slack&labelColor=333a41&message=join%20conversation&color=3AC358" alt="AltinityDB Slack" />
</a>

Terraform module for creating EKS clusters optimized for ClickHouse® with EBS and autoscaling.
It includes the Altinity Kubernetes Operator for ClickHouse and a fully working ClickHouse cluster.

## Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (recommended `>= v1.5`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Usage
### Create an EKS Cluster with Altinity Kubernetes Operator for ClickHouse and ClickHouse Cluster

Paste the following Terraform sample module into a tf file (`main.tf`) in a new directory. Adjust properties as desired.
The sample module will create a Node Pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different Node Pools.

```hcl
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

### Run Terraform to create the cluster

Execute commands to initialize and apply the Terraform module. It will create an EKS cluster and install a ClickHouse sample database.

```sh
terraform init
terraform apply
```

> Setting up the EKS cluster and sample database takes from 10 to 30 minutes depending on the load in your cluster and availability of resources.

### Access your ClickHouse database
Update your kubeconfig with the credentials of your new EKS Kubernetes cluster.
```sh
aws eks update-kubeconfig --region us-east-1 --name clickhouse-cluster
```

Connect to your ClickHouse server using `kubectl exec`.
```sh
kubectl exec -it chi-eks-dev-0-0-0 -n clickhouse -- clickhouse-client
```

### Run Terraform to remove the cluster
After use you can destroy the EKS cluster. First, delete any ClickHouse clusters you have created.
```sh
kubectl delete chi --all --all-namespaces
```

Then, run `terraform destroy` to remove the EKS cluster and any cloud resources.
```sh
terraform destroy
```

## Docs
- [Terraform Registry](https://registry.terraform.io/modules/Altinity/eks-clickhouse/aws/latest)
- [Architecture](https://github.com/Altinity/terraform-aws-eks-clickhouse/tree/master/docs)

## Issues
If a terraform operation does not complete, try running it again. If the problem persists, please [file an issue](https://github.com/Altinity/terraform-aws-eks-clickhouse/issues).

## More Information and Commercial Support
Altinity is the maintainer of this project. Altinity offers a range of
services related to ClickHouse and analytic applications on Kubernetes.

- [Official website](https://altinity.com/) - Get a high level overview of Altinity and our offerings.
- [Altinity.Cloud](https://altinity.com/cloud-database/) - Run ClickHouse in our cloud or yours.
- [Altinity Support](https://altinity.com/support/) - Get Enterprise-class support for ClickHouse.
- [Slack](https://altinitydbworkspace.slack.com/join/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ) - Talk directly with ClickHouse users and Altinity devs.
- [Contact us](https://hubs.la/Q020sH3Z0) - Contact Altinity with your questions or issues.

## Legal
All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2024 Altinity, Inc.
