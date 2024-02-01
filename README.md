**🚨 This module is still under development and not fully tested for production, use it under your own risk**

# terraform-eks-clickhouse

Terraform module for creating EKS clusters optimized for ClickHouse with EBS and autoscaling.

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

> This module will create a Node Pool for each combination of instance type and subnet. For example, if you have 3 subnets and 2 instance types, this module will create 6 different Node Pools.

## Docs

- [Terraform Registry](https://registry.terraform.io/modules/Altinity/eks-clickhouse/aws/latest)
- [Architecture](https://github.com/Altinity/terraform-aws-eks-clickhouse/tree/master/docs)

## TODO

- [ ] Complete docs and add diagram architecture
- [ ] Operator installation alternatives:
  - Use k8s provider `manifest` and split workflow in 2 terraform applies
  - Install the operator using `null_resource` and `kubectl` (with in memory Kubeconfig)
  - Install operator using `kubectl` provider
  - Install the operator manually using `kubectl`
- [ ] Add examples to spin up clickhouse cluster + zookeper
- [ ] Add contact info on `README.md`
- [ ] Add module `examples` directory for TF registry
- [ ] Analyze using static site for docs (vuepress?)
- [ ] Annalize using dynamic subsents generation

## Legal

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2024 Altinity, Inc.
