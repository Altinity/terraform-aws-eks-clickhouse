# EKS Cluster & Node Groups

> 💡 TL;DR: This Terraform configuration leverages the [`terraform-aws-modules/eks/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) module to establish a robust EKS cluster setup. It ensures flexible node group scaling and proper security practices with comprehensive IAM roles and policies. The integration of the Kubernetes Cluster Autoscaler enables dynamic node group scaling based on workload demands.

This Terraform module orchestrates an AWS EKS (Elastic Kubernetes Service) deployment, handling everything from IAM roles to node group configurations using the [`terraform-aws-modules/eks/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest) module. Below is an overview of the key components involved:

### Policy Attachments
- `aws_iam_role.eks_cluster_role`: An IAM role for the EKS cluster with permissions to make AWS API calls on your behalf.
- `aws_iam_role_policy_attachment` resources: Attach AWS-managed policies to the EKS cluster role. These include policies for EKS cluster management, service roles, and VPC resource controllers.
- `aws_iam_policy.eks_admin_policy` and `aws_iam_role.eks_admin_role`: Define an administrative policy and role for EKS. This setup includes permissions for creating and managing EKS clusters and associated IAM roles.
- `aws_iam_role.eks_node_role`: An IAM role for EKS worker nodes to allow them to make AWS API calls.
- `aws_iam_role_policy_attachment` resources for the node role: Attach necessary policies for EKS worker nodes, including EKS worker node policy, CNI plugin policy, and read-only access to ECR (Elastic Container Registry).

### EKS Cluster
- `module.eks_aws.module.eks.aws_eks_cluster.this`: creates an EKS cluster with specified settings like version, role ARN, and subnets configuration.

### EKS Node Group
- `module.eks_aws.module.eks.module.eks_managed_node_group[1-N]`: creates EKS managed node groups for each subnet and instance type combination from the `local.node_pool_combinations`. These node groups are where your Kubernetes pods will run.
- Includes scaling configurations, such as desired, minimum, and maximum size of each node group.
- Tags node groups for integration with the Kubernetes Cluster Autoscaler.
- Specifies disk size and instance types for the node groups, which are essential for defining the resources available to your Kubernetes pods.
- Defines the desired, minimum, and maximum size for the auto-scaling of the node groups.





