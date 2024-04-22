# Kubernetes Cluster Autoscaler

> 💡 TLDR; This setup configures the Cluster Autoscaler to dynamically manage the number of nodes in an AWS EKS cluster based on workload demands, ensuring optimal resource utilization and cost-efficiency.

This Terraform module leverages the `[aws-ia/eks-blueprints-addons/aws](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addon/aws/latest)` to set up the Cluster Autoscaler for an AWS EKS cluster. The setup includes necessary IAM roles and policies, along with Helm for deployment, ensuring that the autoscaler can adjust the number of nodes efficiently. Below is a breakdown of the key components:

### IAM Policy for Cluster Autoscaler
- `aws_iam_policy.cluster_autoscaler`: creates an IAM policy with permissions necessary for the Cluster Autoscaler to interact with AWS services, particularly the Auto Scaling groups and EC2 instances.

### IAM Role for Cluster Autoscaler
- `aws_iam_role.cluster_autoscaler`: defines an IAM role with a trust relationship that allows entities assuming this role via Web Identity (in this case, Kubernetes service accounts) to perform actions as defined in the IAM policy.

### AWS Identity and Access Management
- **`module.eks_aws.module.eks_blueprints_addons.module.cluster_autoscaler.data.aws_caller_identity.current`** and **`module.eks_aws.module.eks_blueprints_addons.module.cluster_autoscaler.data.aws_partition.current`**: Retrieve AWS account details and the partition in which the resources are being created, ensuring that the setup aligns with the AWS environment where the EKS cluster resides.

### Deployment via Helm
- **`module.eks_aws.module.eks_blueprints_addons.module.cluster_autoscaler.helm_release.this`**: Deploys the Cluster Autoscaler using a Helm chart. The configuration is provided through a template file that includes necessary parameters such as the AWS region, cluster ID, autoscaler version, and the role ARN.

