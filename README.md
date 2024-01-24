# terraform-eks-clickhouse

Terraform module for creating EKS clusters optimized for ClickHouse with EBS and autoscaling.

### Usage

```hcl
provider "aws" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
}

provider "kubernetes" {
  # https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs
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
}
```

## Legal

All code, unless specified otherwise, is licensed under the [Apache-2.0](LICENSE) license.
Copyright (c) 2024 Altinity, Inc.

