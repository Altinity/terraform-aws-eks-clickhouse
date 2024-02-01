# EBS & CSI Driver

This Terraform module is configuring the AWS Elastic Block Store (EBS) Container Storage Interface (CSI) driver in a Kubernetes cluster managed by AWS EKS. The EBS CSI driver allows Kubernetes to provision, mount, and manage EBS volumes. Here are the key resources and their roles in this setup:

### IAM Policy and Role for EBS CSI Driver
- `aws_iam_policy_document.ebs_csi_driver_assume_role_policy` and `aws_iam_role.ebs_csi_driver_role`: These define an IAM role that the EBS CSI driver will assume. This role grants the driver permissions to interact with AWS resources like EBS volumes.

### IAM Role Policy Attachment
- `aws_iam_role_policy_attachment.ebs_csi_driver_policy_attachment`: Attaches the `AmazonEBSCSIDriverPolicy` to the IAM role, granting necessary permissions for the CSI driver to manage EBS volumes.

### Kubernetes Service Accounts
- `kubernetes_service_account.ebs_csi_controller_sa` and `kubernetes_service_account.ebs_csi_node_sa`: These service accounts are used by the EBS CSI driver's controller and node components, respectively. The `eks.amazonaws.com/role-arn` annotation links these accounts to the IAM role created earlier.

### Kubernetes Cluster Roles and Role Bindings
- Resources like `kubernetes_cluster_role.ebs_external_attacher_role` and related `kubernetes_cluster_role_binding.ebs_csi_attacher_binding`: These define the permissions required by the EBS CSI driver within the Kubernetes cluster, following the principle of least privilege.

### Kubernetes DaemonSet and Deployment
- `kubernetes_daemonset.ebs_csi_node`: Deploys the EBS CSI driver on each node in the cluster. This daemonset is responsible for operations like mounting and unmounting EBS volumes on the nodes.
- `kubernetes_deployment.ebs_csi_controller`: Deploys the controller component of the EBS CSI driver, which is responsible for provisioning and managing the lifecycle of EBS volumes.

### CSI Driver and Storage Class
- `kubernetes_csi_driver_v1.ebs_csi_aws_com`: Registers the `ebs.csi.aws.com` CSI driver in the Kubernetes cluster.
- `kubernetes_storage_class.gp3-encrypted`: Defines a storage class for provisioning EBS volumes. This particular storage class is set to use the `gp3` volume type and encrypt the volumes. (which is what we recommended for ClickHouse)

> 💡 TL;DR This configuration sets up the necessary IAM roles and policies, Kubernetes roles, service accounts, and deployments to enable the AWS EBS CSI driver in an EKS cluster. This setup allows the Kubernetes cluster to dynamically provision EBS volumes as persistent storage for pods, leveraging the capabilities of AWS EBS.
