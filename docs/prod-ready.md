# Getting Production Ready

Deploying applications in a production environment necessitates stringent security measures to mitigate risks such as unauthorized access and potential data breaches. A secure Kubernetes deployment minimizes these risks by restricting public internet exposure of critical components and enforcing data encryption. This guideline outlines essential steps to achieve a secure and robust production environment.

## Restrict Kubernetes API Access

You can restrict access to the Kubernetes API by setting the module variable `eks_endpoint_public_access` to `false`:

```hcl
eks_endpoint_public_access = false
```

This will restrict access to the Kubernetes API to the VPC only, **that means that the module needs to be run from within the VPC**.

> If you still need to access the Kubernetes API from the public Internet, consider restricting access to specific IP addresses using the `eks_public_access_cidrs` variable.

## Remove Public Load Balancer

Utilizing public load balancers, especially for database clusters like ClickHouse®, poses a significant security risk by exposing your services to the public internet. This can lead to unauthorized access and potential data exploitation.

Switch to a private load balancer by setting `clickhouse_cluster_enable_loadbalancer` to `false`. This adjustment allows for dynamic creation or removal of the load balancer, aligning with security best practices.

## Change Default Passwords (and Kubernetes Secrets)
When setting up the cluster, you can configure the ClickHouse default credentials by setting the `clickhouse_cluster_password` and `clickhouse_cluster_password` variables. If you don't provide a password, the module will generate a random one for you. The credentials will be store in the terraform state and also in a Kubernetes secret named `clickhouse-credentials`.

Consider changing credential values in the Kubernetes secrets to enhance security. Even if you set random/strong passwords, the initial values will be part of state files, logs, or other artifacts, which could lead to unauthorized access.

> **Important:** The ClickHouse password is stored in plaintext in the Terraform state file. This is a Terraform limitation that affects all sensitive values. For production environments, use a [remote backend](https://developer.hashicorp.com/terraform/language/backend) with encryption enabled (e.g., S3 with SSE) and restrict access to the state file.

## Enable Secrets Encryption

By default, Kubernetes secrets are stored without envelope encryption in etcd. While AWS encrypts the underlying EBS volumes of the EKS control plane, enabling envelope encryption adds a layer of protection using a customer-managed KMS key.

```hcl
eks_enable_secrets_encryption = true
```

This creates a KMS key and configures EKS to use it for encrypting secrets at rest. This is recommended for any environment handling sensitive data.

## Enable Control Plane Logging

EKS control plane logs provide visibility into API calls, authentication events, and cluster operations. These logs are sent to CloudWatch and can help with debugging, auditing, and security monitoring.

```hcl
eks_cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
```

> **Note:** Control plane logs incur CloudWatch costs. For cost-sensitive environments, start with `["audit", "authenticator"]` as a minimum.

## High Availability NAT Gateway

By default, the module creates a single NAT Gateway shared across all availability zones. If the AZ hosting the NAT Gateway goes down, all nodes in private subnets lose Internet connectivity. For production, create one NAT Gateway per AZ:

```hcl
eks_single_nat_gateway = false
```

> **Note:** Each NAT Gateway has an hourly cost plus data processing charges. A NAT Gateway per AZ increases networking costs but eliminates a single point of failure.

## Data Backup and Recovery

The default StorageClass (`gp3-encrypted`) uses `reclaimPolicy: Delete`, which means EBS volumes are destroyed when their PVC is deleted. Do not rely on storage reclaim policies for data protection. Instead, implement a proper backup strategy:

- **EBS Snapshots**: Schedule automated snapshots of ClickHouse data volumes via AWS Backup or lifecycle policies.
- **clickhouse-backup**: Use [clickhouse-backup](https://github.com/Altinity/clickhouse-backup) to create logical or physical backups to S3.

## Clickhouse Cluster Sharding
> TBA

## Clickhouse Keeper High Availability
> TBA


