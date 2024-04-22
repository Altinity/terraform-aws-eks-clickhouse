# EBS & CSI Driver

> 💡 TL;DR This configuration sets up the necessary IAM roles and policies, Kubernetes roles, service accounts, and deployments to enable the AWS EBS CSI driver in an EKS cluster. This setup allows the Kubernetes cluster to dynamically provision EBS volumes as persistent storage for pods, leveraging the capabilities of AWS EBS.

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



# AWS EBS CSI Driver Setup

> 💡 TLDR; This configuration sets up the AWS EBS CSI driver within an EKS cluster, enabling dynamic provisioning of EBS volumes for persistent storage. The setup includes the necessary IAM roles, Kubernetes roles, service accounts, and driver deployments to integrate AWS EBS efficiently with the Kubernetes environment.

This Terraform module configures the AWS Elastic Block Store (EBS) Container Storage Interface (CSI) driver using the `[aws-ia/eks-blueprints-addons/aws](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addon/aws/latest)` module for a Kubernetes cluster managed by AWS EKS. The AWS EBS CSI driver facilitates the provisioning, mounting, and management of AWS EBS volumes directly via Kubernetes. Below is a detailed breakdown of the components involved in this setup:

### IAM Setup for EBS CSI Driver
- **`module.eks_aws.aws_iam_role.ebs_csi_driver_role`**: Defines an IAM role that the EBS CSI driver will assume. This role grants the driver permissions to interact with AWS resources necessary for managing EBS volumes.
- **`module.eks_aws.aws_iam_role_policy_attachment.ebs_csi_driver_policy_attachment`**: Attaches the necessary IAM policies to the IAM role, specifically the `AmazonEBSCSIDriverPolicy`, empowering the CSI driver to perform operations on EBS volumes.

### EKS Addon Configuration
- **`module.eks_aws.module.eks_blueprints_addons.aws_eks_addon.this["aws-ebs-csi-driver"]`**: Configures the AWS EBS CSI driver as an EKS addon, simplifying management and ensuring it is kept up-to-date with the latest releases and security patches.

### Kubernetes Storage Class
- **`kubernetes_storage_class.gp3-encrypted`**: Defines a storage class named `gp3-encrypted`, which is set as the default class for dynamic volume provisioning. It uses the `gp3` volume type with encryption enabled, suitable for applications requiring secure and performant storage solutions.
  - **Parameters**: Specifies encryption, filesystem type (`ext4`), and the volume type (`gp3`).
  - **Reclaim Policy**: Set to `Delete`, meaning volumes will be automatically deleted when the corresponding Kubernetes persistent volume is deleted.
  - **Volume Binding Mode**: Set to `WaitForFirstConsumer`, which delays the binding and provisioning of a volume until a pod using it is scheduled.

### Integration and Dependency Management
- **Depends on**: Ensures that the EBS CSI driver setup only begins after the necessary EKS cluster components (such as the cluster itself and related IAM roles) are fully provisioned and operational.
