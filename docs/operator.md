# Altinity ClickHouse Operator

This Terraform module orchestrates the setup and deployment of the [Altinity ClickHouse Operator](https://github.com/Altinity/clickhouse-operator) on an AWS EKS cluster. Here's a breakdown of each component in the configuration:

### Local Variables
- `locals.manifest`: Points to the ClickHouse Operator manifest file's path. This is the Kubernetes manifest that defines the ClickHouse Operator resources.
`locals.kubeconfig`: Dynamically generates a kubeconfig for the AWS EKS cluster. This configuration enables kubectl to interact with the EKS cluster, specifying details like the cluster API server endpoint and authentication data.

### Trigger Mechanism:
- `null_resource`: It tracks changes in both the `kubeconfig` and the `clickhouse-operator.yaml` manifest. Any changes in these files will cause Terraform to re-run the `null_resource`, ensuring that updates or modifications are applied.
- The `local-exec` block invokes a bash script (`install-clickhouse-operator.sh`) with the generated `kubeconfig` and the manifest file as arguments. This script handles the deployment logic of the ClickHouse Operator.

### Intall Process
1. The script first sets up a temporary kubeconfig file for authenticating with the EKS cluster.
2. It then checks if the ClickHouse Operator is already applied and if there are any differences between the applied and current manifests.
3. If differences are detected, and the `var.confirm_operator_manifest_changes` variable is `false`, it prompts the user to confirm the changes by re-running Terraform apply with the variable set to true (`terraform plan -var="confirm_operator_manifest_changes=true"`)
4 Finally, it applies the manifest using kubectl apply and cleans up the temporary kubeconfig file.

> 💡 TL;DR: This Terraform setup automates the deployment of the ClickHouse Operator on an AWS EKS cluster. It dynamically generates kubeconfig for EKS interaction, monitors changes in the Operator's manifest, and uses a Bash script for intelligent deployment handling, including diff checks and optional confirmation steps for applying changes. This architecture ensures a smooth and controlled deployment process, allowing for easy updates and maintenance of the ClickHouse Operator in a Kubernetes environment managed by AWS EKS.