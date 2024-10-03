# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.1.0...v0.1.1)
### Added
- New `outputs.tf` file with `eks_node_groups` and `eks_cluster` outputs.

## [0.1.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/releases/tag/v0.1.0)
### Added
- EKS cluster optimized for ClickHouse® with EBS driver and autoscaling.
- VPC, subnets, and security groups.
- Node Pools for each combination of instance type and subnet.
