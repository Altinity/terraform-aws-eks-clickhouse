**🚨 This module is still under development and not fully ready for production use; use it at your own risk.**

# terraform-aws-eks-clickhouse

[![License](http://img.shields.io/:license-apache%202.0-brightgreen.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![issues](https://img.shields.io/github/issues/altinity/terraform-aws-eks-clickhouse.svg)](https://github.com/altinity/terraform-aws-eks-clickhouse/issues)
<a href="https://join.slack.com/t/altinitydbworkspace/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ">
  <img src="https://img.shields.io/static/v1?logo=slack&logoColor=959DA5&label=Slack&labelColor=333a41&message=join%20conversation&color=3AC358" alt="AltinityDB Slack" />
</a>

Terraform module for creating EKS clusters optimized for ClickHouse with EBS and autoscaling.
It includes the ClickHouse Operator and a fully working ClickHouse cluster.

## Prerequisites

- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) (recommended `>= v1.5`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).

## Usage
### Create an EKS Cluster with ClickHouse Operator and ClickHouse Cluster
```hcl
locals {
  region = "us-east-1"
}

module "eks_clickhouse" {
  source  = "github.com/Altinity/terraform-aws-eks-clickhouse"

  install_clickhouse_operator = true
  install_clickhouse_cluster  = true

  cluster_name = "clickhouse-cluster"
  region       = local.region
  cidr         = "10.0.0.0/16"
  subnets      = [
    { cidr_block = "10.0.1.0/24", az = "${local.region}a" },
    { cidr_block = "10.0.2.0/24", az = "${local.region}b" },
    { cidr_block = "10.0.3.0/24", az = "${local.region}c" }
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

  tags = {
    CreatedBy = "mr-robot"
  }
}

output "clickhouse_cluster_url" {
  value = module.eks_clickhouse.clickhouse_cluster_url
}

output "clickhouse_cluster_password" {
  value     = module.eks_clickhouse.clickhouse_cluster_password
  sensitive = true
}
```

> Setting up the EKS cluster and sample database takes from 10 to 30 minutes depending on the load in your cluster and availability of resources.

### Access your ClickHouse database
Update your kubeconfig with the credentials of your new EKS Kubernetes cluster.
```sh
aws eks update-kubeconfig --region us-east-1 --name clickhouse-cluster
```

Connect to your ClickHouse server using `kubectl exec`.
```sh
kubectl exec -it chi-chi-chi-0-0-0 -n clickhouse -- clickhouse-client
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
