# K8S Autoscaler

This Terraform module sets up the Cluster Autoscaler for an AWS EKS cluster. The Cluster Autoscaler automatically adjusts the number of nodes in your Kubernetes cluster when pods fail to launch due to insufficient resources or when nodes are underutilized and their workloads can be moved elsewhere. Here's a breakdown of the key components:

### IAM Policy for Cluster Autoscaler
- `aws_iam_policy.cluster_autoscaler`: creates an IAM policy with permissions necessary for the Cluster Autoscaler to interact with AWS services, particularly the Auto Scaling groups and EC2 instances.

### IAM Role for Cluster Autoscaler
- `aws_iam_role.cluster_autoscaler`: defines an IAM role with a trust relationship that allows entities assuming this role via Web Identity (in this case, Kubernetes service accounts) to perform actions as defined in the IAM policy.

### IAM Role Policy Attachment
- `aws_iam_role_policy_attachment.cluster_autoscaler_attach`: attaches the created IAM policy to the IAM role, granting the specified permissions to the role.

### Kubernetes Service Account
- `kubernetes_service_account.cluster_autoscaler`: creates a service account in Kubernetes for the Cluster Autoscaler. The annotation `eks.amazonaws.com/role-arn` binds this service account to the previously created IAM role.

### Kubernetes Cluster Role and Role Binding
- `kubernetes_cluster_role.cluster_autoscaler`: the Cluster Role defines permissions at the cluster level required by the Cluster Autoscaler to function correctly, such as accessing and modifying nodes, pods, and other resources.
- `kubernetes_cluster_role_binding.cluster_autoscaler`: the Cluster Role Binding grants these permissions to the specified service account.

### Kubernetes Role and Role Binding for ConfigMaps
- `kubernetes_role.cluster_autoscaler` and `kubernetes_role_binding.cluster_autoscaler`: provide permissions specifically for managing `ConfigMaps` in the `kube-system` namespace, which is necessary for Cluster Autoscaler's configuration and status reporting.

### Kubernetes Deployment
- `kubernetes_deployment.cluster_autoscaler`: deploys the Cluster Autoscaler application in the Kubernetes cluster. It includes the container image for the Cluster Autoscaler, resource requests and limits, and specific configurations like command-line arguments to control its behavior.
- This also includes affinity settings to ensure that the autoscaler pods do not co-locate on the same host, which is a best practice for high availability.

> 💡 TLDR; This setup ensures that the Cluster Autoscaler in Kubernetes has the necessary permissions and configuration to manage node scaling within an AWS EKS cluster. The autoscaler will monitor the load and resource requirements of the pods and adjust the number of nodes in the cluster accordingly.