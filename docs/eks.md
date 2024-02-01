# EKS Cluster & Node Groups

This Terraform module sets up an AWS EKS (Elastic Kubernetes Service) cluster with an associated node group configuration. It also establishes the necessary IAM roles and policies for the EKS cluster, node groups, and administrative tasks. Let's break down the key components:

## Policy Attachments
- `aws_iam_role.eks_cluster_role`: An IAM role for the EKS cluster with permissions to make AWS API calls on your behalf.
- `aws_iam_role_policy_attachment` resources: Attach AWS-managed policies to the EKS cluster role. These include policies for EKS cluster management, service roles, and VPC resource controllers.
- `aws_iam_policy.eks_admin_policy` and `aws_iam_role.eks_admin_role`: Define an administrative policy and role for EKS. This setup includes permissions for creating and managing EKS clusters and associated IAM roles.
- `aws_iam_role.eks_node_role`: An IAM role for EKS worker nodes to allow them to make AWS API calls.
- `aws_iam_role_policy_attachment` resources for the node role: Attach necessary policies for EKS worker nodes, including EKS worker node policy, CNI plugin policy, and read-only access to ECR (Elastic Container Registry).

### AWS IAM OpenID Connect Provider:
- `aws_iam_openid_connect_provider.this`): sets up an (OIDC identity provider)[https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html] for the EKS cluster to enable IAM roles for service accounts.

### EKS Cluster
- `aws_eks_cluster.this`: creates an EKS cluster with specified settings like version, role ARN, and VPC configuration.

### EKS Node Group
- `aws_eks_node_group.this`: creates EKS node groups for each subnet and instance type combination from the `local.node_pool_combinations`. These node groups are where your Kubernetes pods will run.
- Includes scaling configurations, such as desired, minimum, and maximum size of each node group.
- Tags node groups for integration with Kubernetes Cluster Autoscaler.
- Specifies disk size and instance types for the node groups, which are essential for defining the resources available to your Kubernetes pods.
- Defines the desired, minimum, and maximum size for the auto-scaling of the node groups.

> 💡 TL;DR This configuration is a comprehensive setup for managing an EKS cluster with flexibility in node group scaling and distribution across multiple subnets and instance types. It ensures the EKS cluster and its worker nodes have the correct IAM roles and policies for secure and efficient operation. Additionally, the integration with Kubernetes Cluster Autoscaler allows for dynamic scaling of the node groups based on workload demands.





