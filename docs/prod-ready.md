# Getting Production Ready

Deploying applications in a production environment necessitates stringent security measures to mitigate risks such as unauthorized access and potential data breaches. A secure Kubernetes deployment minimizes these risks by restricting public internet exposure of critical components and enforcing data encryption. This guideline outlines essential steps to achieve a secure and robust production environment.

## Restrict Kubernetes API Access

You can simply restrict the access to the Kubernetes API by setting the module variable `eks_endpoint_public_access` to `false`.
This will restrict access to the Kubernetes API to the VPC only, **that means that the module needs to be run from within the VPC**.

If you don't want to do that, a possible workaround is to manually change this property using the AWS CLI after the cluster is created.

```sh
aws eks update-cluster-config \
  --region <region> \
  --name <cluster-name> \
  --resources-vpc-config endpointPublicAccess=false
```

> If for some reason you still need to access the Kubernetes API from the public Internet, consider restricting access to specific IP addresses using the `eks_public_access_cidrs` variable.

## Remove Public Load Balancer

Utilizing public load balancers, especially for database clusters like ClickHouse, poses a significant security risk by exposing your services to the public internet. This can lead to unauthorized access and potential data exploitation.

Switch to a private load balancer by setting `clickhouse_cluster_enable_loadbalancer` to `false`. This adjustment allows for dynamic creation or removal of the load balancer, aligning with security best practices.

## Change Default Passwords (and Kubernetes Secrets)
When setting up the cluster, you can configure the ClickHouse default credentials by setting the `clickhouse_cluster_password` and `clickhouse_cluster_password` variables. If you don't provide a password, the module will generate a random one for you. The credentials will be store in the terraform state and also in a Kubernetes secret named `clickhouse-credentials`.

Consider changing credential values in the Kubernetes secrets to enhance security. Even if you set random/strong passwords, the initial values will be part of state files, logs, or other artifacts, which could lead to unauthorized access.

## Cluster Monitoring and Logging

> TBA

