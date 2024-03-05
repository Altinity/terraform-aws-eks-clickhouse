[![License](http://img.shields.io/:license-apache%202.0-brightgreen.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![issues](https://img.shields.io/github/issues/altinity/terraform-aws-eks-clickhouse.svg)](https://github.com/altinity/terraform-aws-eks-clickhouse/issues)
<a href="https://join.slack.com/t/altinitydbworkspace/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ">
  <img src="https://img.shields.io/static/v1?logo=slack&logoColor=959DA5&label=Slack&labelColor=333a41&message=join%20conversation&color=3AC358" alt="AltinityDB Slack" />
</a>

**🚨 This module is still under development and not fully ready for production use; use it at your own risk.**

# terraform-aws-eks-clickhouse

Terraform module for creating EKS clusters optimized for ClickHouse with EBS and autoscaling.

## Quick Start

### Prerequisites

Install [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).

### Create Terraform file

Paste the following Terraform sample module into file clickhouse-eks.tf in a new directory. Adjust properties as desired. The sample module will create a Node Pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different Node Pools.

```hcl
provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
}

module "eks_clickhouse" {
  source  = "github.com/Altinity/terraform-aws-eks-clickhouse"

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

  tags = {
    CreatedBy = "mr-robot"
  }
}

output "get_load_balancer" {
  value = module.eks_clickhouse.get_load_balancer
}

output "clickhouse_cluster_password" {
  value     = module.eks_clickhouse.clickhouse_cluster_password
  sensitive = true
}
```
### Run Terraform to create the cluster

Execute commands to initialize and apply the Terraform module. It will create an EKS cluster and install a ClickHouse sample database.
```
terraform init
terraform apply
```
Setting up the EKS cluster and sample database takes from 10 to 20 minutes depending on the load in your cluster and availability of resources.

### Access your ClickHouse database

Get credentials for the EKS Kubernetes cluster.
```
aws eks update-kubeconfig --region us-east-1 --name clickhouse-cluster
```

Connect to your ClickHouse server using `kubectl exec`.
```
kubectl exec -it chi-chi-chi-0-0-0 -n clickhouse -- clickhouse-client
```

### Run Terraform to remove the cluster

After use you can destroy the EKS cluster.  First, delete any ClickHouse clusters you have created.
```
kubectl delete chi --all --all-namespaces
```

Second, run `terraform destroy` to remove the EKS cluster and any cloud resources.
```
terraform destroy
```

### Problems?
If a terraform operation does not complete, try running it again. If the problem persists, please [file an issue](https://github.com/Altinity/terraform-aws-eks-clickhouse/issues).

## Docs

- [Terraform Registry](https://registry.terraform.io/modules/Altinity/eks-clickhouse/aws/latest)
- [Architecture](https://github.com/Altinity/terraform-aws-eks-clickhouse/tree/master/docs)

## TODO

- [ ] Finish docs and add diagram architecture
- [ ] Add contact info on `README.md`
- [ ] Add module `examples` directory for TF registry
- [ ] ~~Add `addons` for the module~~
- [ ] ~~Nat and private subnets~~

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
