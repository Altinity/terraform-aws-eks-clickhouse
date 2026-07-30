# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.7...v0.6.0)
### Added
- Identify node AMI type based on instance selection ([383b21f](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/383b21f)).
- Migrate to EKS 1.34 ([a2e03fa](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a2e03fa)).
- Add optional secrets encryption and control plane logging ([6852279](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/6852279)).
- Add `eks_endpoint_public_access` variable ([9d80e03](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/9d80e03)).
- Add `eks_single_nat_gateway` variable for HA networking ([2a01854](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/2a01854)).
- Add `eks_autoscaler_replicas` variable ([7d6235d](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7d6235d)).
- Add a CI workflow (fmt, validate, tflint, examples), a Makefile, and pre-commit hooks ([6e549da](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/6e549da)).
- Add a data backup and recovery section to the prod-ready guide ([0c4a330](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0c4a330)).
- Add `eks_autoscaler_chart_version` (`autoscaler_chart_version`) variable to pin the cluster-autoscaler Helm chart version ([#35](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/35), [0abd589](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0abd589)).
- Add an EKS upgrade runbook at `docs/upgrading-eks.md` ([#35](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/35), [0abd589](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0abd589)).
- Add a trivy security scan job to CI ([#35](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/35), [0abd589](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0abd589)).

### Changed
- Bump eks_blueprints_addons to 1.22.0 ([94ff930](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/94ff930)).
- Keep helm versions consistent with AWS addons ([ed7ae80](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/ed7ae80)).
- Bump EKS version to 1.33 ([c20336a](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c20336a)).
- Improve README and add contributing guide ([5b18c41](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/5b18c41)).
- Add compatibility note and fixed examples ([82edc95](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/82edc95)).
- Upgrade exec credential API from v1beta1 to v1 ([7cbc458](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7cbc458)).
- Update examples to consume the local module source (`../..`) so CI validates the working tree ([#35](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/35), [0abd589](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0abd589)).

### Deprecated
- Deprecate `autoscaler_replicas` in favor of `eks_autoscaler_replicas` ([7d6235d](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7d6235d)).

### Fixed
- Fix cluster-autoscaler never scaling on EKS 1.34 by pinning the Helm chart to 9.53.0 — the previous chart (9.35.0) shipped a ClusterRole missing `volumeattachments` RBAC, which blocked the autoscaler's informer sync and silently stopped scaling; also ensure `eks_autoscaler_version` actually controls the deployed image via `image_tag_override` (previously silently ignored), and bump the default autoscaler image to 1.34.5 ([#35](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/35), [0abd589](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0abd589)).
- Validate node pool zones exist in the configured availability zones ([fb7daec](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/fb7daec)).
- Correct default availability zones, fix a crash on null node pool labels, and remove a dead variable ([#33](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/33), [56cd791](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/56cd791)).
- Resolve ClickHouse instance type by name instead of by index ([26788a2](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/26788a2)).
- Validate that at least one ClickHouse node pool exists ([5dde29d](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/5dde29d)).
- Add CIDR and availability zone count validation ([9799fbf](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/9799fbf)).
- Add `aud` condition to OIDC trust policies ([549c9bf](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/549c9bf)).
- Use a heredoc instead of `echo` for kubeconfig in the local-exec provisioner ([a11f288](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a11f288)).
- Clean up the temporary kubeconfig file in the load-balancer script ([fbcb5b9](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/fbcb5b9)).
- Remove deprecated `AmazonEKSServicePolicy` attachment ([dbc703c](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/dbc703c)).

## [0.5.7](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.6...v0.5.7)
### Changed
- Update default EKS to 1.32 ([780fd7b](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/780fd7b)).

## [0.5.6](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.5...v0.5.6)
### Changed
- Update default ClickHouse operator to v0.24.4 ([66d7f49](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/66d7f49)).

## [0.5.5](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.4...v0.5.5)
### Changed
- Remove non-prod ready note ([89692d1](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/89692d1)).

## [0.5.4](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.3...v0.5.4)
### Changed
- Update clickhouse-eks to v0.1.8 ([935312b](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/935312b)).

## [0.5.3](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.2...v0.5.3)
### Fixed
- Update ClickHouse chart version to fix wrong tolerations case ([2240407](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/2240407)).

## [0.5.2](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.1...v0.5.2)
### Added
- Allow change chart versions from variables ([6be3085](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/6be3085)).
- Add default taints for ClickHouse nodes ([#21](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/21), [989cb69](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/989cb69)).

## [0.5.1](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.5.0...v0.5.1)
### Added
- Add a label identifying the module to node groups by default ([#20](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/20), [8329aa4](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/8329aa4)).

### Changed
- Improve CIDR vars description ([2055a0f](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/2055a0f)).

## [0.5.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.4.0...v0.5.0)
### Added
- Migrate to new keeper chart ([2744c18](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/2744c18)).

### Fixed
- Ensure the system pool creates a node in the first zone even when desired_size=0 ([#19](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/19), [7268cda](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7268cda)).

### Changed
- Add comment about index 0 node pool ([4cda523](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/4cda523)).
- Cleaned up trademarks and other details ([#18](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/18), [a7318b3](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a7318b3)).
- Update product names to meet naming standards ([db7a448](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/db7a448)).

## [0.4.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.3.3...v0.4.0)
### Added
- Add new node pools variable setup ([#17](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/17), [b9f2632](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/b9f2632)).

### Changed
- Re-use local.region in examples ([9de3548](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/9de3548)).

## [0.3.3](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.3.2...v0.3.3)
### Fixed
- Set aws_profile to null ([58fa435](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/58fa435)).

## [0.3.2](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.3.1...v0.3.2)
### Added
- AWS-CLI exe feature to allow AWS profiles to be used dynamically ([#16](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/16), [b6e3820](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/b6e3820)).

## [0.3.1](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.3.0...v0.3.1)
### Fixed
- Provider in module conflicting with local provider ([#15](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/15), [1442b0e](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/1442b0e)).
- Fix pod-to-pod connectivity across different nodes ([#14](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/14), [06b27d1](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/06b27d1)).

### Changed
- Add AWS provider setup to examples ([41021b5](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/41021b5)).
- Update README.md to add aws-cli link ([1d74b17](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/1d74b17)).
- Update blueprints and prod guide ([c587b30](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c587b30)).

## [0.3.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.2.1...v0.3.0)
### Added
- Migrate default Kubernetes to 1.29 ([be2e737](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/be2e737)).
- Add labels and taints variables ([359153a](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/359153a)).
- Add dynamic NAT gateway ([b02417c](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/b02417c)).
- Add NAT gateway support and private subnets ([00a4bf8](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/00a4bf8)).
- Use new Altinity helm charts ([223e53f](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/223e53f)).
- Add multi zones support to ClickHouse pods ([c31c54f](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c31c54f)).

### Fixed
- Make labels and taints optional ([4565f13](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/4565f13)).
- Correct README sample indentation ([25679dc](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/25679dc)).
- Remove quotes in region ([52523ca](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/52523ca)).
- Use eks_tags in readmes ([1a0b5f2](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/1a0b5f2)).
- Add missing SECONDS variable ([20e1ef5](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/20e1ef5)).
- Typo on install variable names ([ce51d23](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/ce51d23)).

### Changed
- Used fixed versions for AWS modules ([9c12986](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/9c12986)).
- Disabled default gp2 storageclass ([e8a3e4b](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/e8a3e4b)).
- Add new point to prod-ready guide ([95f03f1](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/95f03f1)).
- Remove deprecated manifests ([e3b231f](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/e3b231f)).
- Add new examples ([a2b81d1](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a2b81d1)).
- Update defaults and fix README examples ([9ed015a](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/9ed015a)).
- Move to latest chart version ([60a4bf2](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/60a4bf2)).
- Add AWS modules, helm charts and misc improvements ([37f8e0b](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/37f8e0b)).
- Migrate to AWS VPC module ([c0d61f9](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c0d61f9)).
- Add back terraform instructions ([0655bfc](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0655bfc)).
- Add prod ready draft ([e28b742](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/e28b742)).
- Add clickhouse_cluster_enable_loadbalancer to README ([55a89d9](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/55a89d9)).
- Remove unused variables and add examples ([34377a3](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/34377a3)).
- Update arch diagram ([245fc85](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/245fc85)).
- Make loadbalancer configurable ([e62250a](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/e62250a)).
- Bring back destroy instructions ([097e3b7](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/097e3b7)).
- Add examples directory ([b983e1d](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/b983e1d)).
- Default clickhouse_cluster_wait_for_loadbalancer to true ([413abc6](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/413abc6)).
- Fix outputs on README ([7180a25](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7180a25)).
- Add arch diagram v2 ([1589929](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/1589929)).
- Add Altinity contact info ([dc2e074](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/dc2e074)).
- Add code comments ([d138956](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/d138956)).
- Add arch diagram v1 ([0a5db88](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0a5db88)).
- Add comments to blueprint ([db76c81](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/db76c81)).
- Rename ClickHouse cluster vars and fix wait for load balancer resource ([18402cb](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/18402cb)).

## [0.2.1](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.2.0...v0.2.1)
### Added
- Add shards and replicas variables ([90ad9f6](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/90ad9f6)).
- Add affinity to ClickHouse pods ([7bc8aa0](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7bc8aa0)).

### Changed
- Cleanup README ([37fd0be](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/37fd0be)).
- Add details to docs ([#6](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/6), [6415b99](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/6415b99)).
- Remove TODO from README ([6d3bdbb](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/6d3bdbb)).

## [0.2.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.1.1...v0.2.0)
### Added
- Add variables to toggle ClickHouse installation ([a4b2d01](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a4b2d01)).
- Add wait_for_clickhouse_loadbalancer and output get loadbalancer command ([edc533e](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/edc533e)).
- Add waiter for ClickHouse load balancer ([876a5e0](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/876a5e0)).
- Add tflint and set missing vars ([e8bc9c8](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/e8bc9c8)).
- Add ZooKeeper and multi cluster setup ([bee2514](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/bee2514)).
- Add clickhouse-operator with kubectl provider ([89c35fb](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/89c35fb)).
- Add clickhouse-operator with null_resource ([ed6ca44](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/ed6ca44)).

### Fixed
- Fix typo on blueprints ([41acba6](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/41acba6)).
- Add dynamic token for k8s connection ([a8981a5](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a8981a5)).
- Add cluster name prefix to autoscaler policies ([d45d70b](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/d45d70b)).
- Add destroy hook to check for load balancer ([a35d5a2](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/a35d5a2)).
- Add kubeconfig to lb null resource and improve tags ([8b17c62](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/8b17c62)).
- Remove providers from eks ([ffa5d30](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/ffa5d30)).
- Add provider config and fix variable names ([0003d00](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/0003d00)).
- Fix typo on ClickHouse URL output ([4bb3356](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/4bb3356)).
- Add missing variable to main module ([1162843](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/1162843)).
- Ignore desired_size changes ([4565306](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/4565306)).

### Changed
- Add outputs sample to README ([1d3e2f4](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/1d3e2f4)).
- Upgrade operator to 0.23.3 and move ZooKeeper to cluster module ([c61ca45](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c61ca45)).
- Upgrade operator to 0.23.2 ([46d3319](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/46d3319)).
- Full quick start and contact information for Altinity ([7c29252](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7c29252)).
- Remove loadbalancer verification ([c124dd6](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c124dd6)).
- Minor changes, link updates, etc. ([#1](https://github.com/Altinity/terraform-aws-eks-clickhouse/pull/1), [f713fef](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/f713fef)).
- Add next steps and improve wording ([c207dad](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/c207dad)).
- Improve architecture README ([7f5cba6](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/7f5cba6)).
- Add code annotations ([3e9a883](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/3e9a883), [20d7dc7](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/20d7dc7)).
- Update ClickHouse reference ([13a8abb](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/13a8abb)).
- Move token to eks outputs ([f127588](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/f127588)).
- Split operator and cluster in 2 modules ([bf21bb2](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/bf21bb2)).
- Fix minor lint issues ([13ae9e1](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/13ae9e1)).
- Improve format and wording ([e23aef5](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/e23aef5)).
- Add TODO to README ([3a41a52](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/3a41a52)).
- Add entries to changelog ([13608bb](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/13608bb)).

## [0.1.1](https://github.com/Altinity/terraform-aws-eks-clickhouse/compare/v0.1.0...v0.1.1)
### Added
- New `outputs.tf` file with `eks_node_groups` and `eks_cluster` outputs ([b92801f](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/b92801f)).

### Changed
- Add registry entry to readme ([f1869fd](https://github.com/Altinity/terraform-aws-eks-clickhouse/commit/f1869fd)).

## [0.1.0](https://github.com/Altinity/terraform-aws-eks-clickhouse/releases/tag/v0.1.0)
### Added
- EKS cluster optimized for ClickHouse® with EBS driver and autoscaling.
- VPC, subnets, and security groups.
- Node Pools for each combination of instance type and subnet.
