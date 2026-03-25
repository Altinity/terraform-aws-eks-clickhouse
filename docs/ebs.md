# EBS & CSI Driver

> **TL;DR**: This configuration sets up the AWS EBS CSI driver within an EKS cluster using the EKS Blueprints Addons module, enabling dynamic provisioning of encrypted gp3 EBS volumes for persistent storage.

This Terraform module configures the AWS Elastic Block Store (EBS) Container Storage Interface (CSI) driver for the EKS cluster using the [`aws-ia/eks-blueprints-addons/aws`](https://registry.terraform.io/modules/aws-ia/eks-blueprints-addon/aws/latest) module. The AWS EBS CSI driver facilitates the provisioning, mounting, and management of AWS EBS volumes directly via Kubernetes.

### IAM Setup for EBS CSI Driver
- **`aws_iam_role.ebs_csi_driver_role`**: Defines an IAM role that the EBS CSI driver pods will assume via IRSA (IAM Roles for Service Accounts). The trust policy is scoped to the cluster's OIDC provider with `sub` and `aud` conditions for secure access.
- **`aws_iam_role_policy_attachment.ebs_csi_driver_policy_attachment`**: Attaches the `AmazonEBSCSIDriverPolicy` managed policy to the IAM role, granting the CSI driver permissions to manage EBS volumes.

### EKS Addon Configuration
- **`module.eks_blueprints_addons`**: Configures the AWS EBS CSI driver as an EKS managed addon via the EKS Blueprints Addons module. This simplifies management and ensures the driver is kept up-to-date with the latest releases and security patches.

### Kubernetes Storage Class
- **`kubernetes_storage_class_vi.gp3-encrypted`**: Defines a storage class named `gp3-encrypted`, set as the default class for dynamic volume provisioning:
  - **Type**: `gp3` (latest generation general purpose SSD)
  - **Encryption**: Enabled by default
  - **Filesystem**: `ext4`
  - **Reclaim Policy**: `Delete` — volumes are automatically deleted when the corresponding PVC is deleted
  - **Volume Binding Mode**: `WaitForFirstConsumer` — delays volume provisioning until a pod is scheduled, ensuring the volume is created in the correct availability zone

### Default Storage Class
- **`kubernetes_annotations.disable_gp2`**: Disables the default `gp2` storage class that comes with EKS, ensuring `gp3-encrypted` is used as the default for all persistent volume claims.
