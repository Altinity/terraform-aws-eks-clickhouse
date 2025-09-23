---
name: Bug report
about: Report a bug or issue with the Terraform AWS EKS ClickHouse module
title: '[BUG] '
labels: 'bug'
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**Environment**
- Terraform version: [e.g. 1.5.0]
- Module version: [e.g. latest, or specific commit/tag]
- AWS CLI version: [e.g. 2.13.0]
- kubectl version: [e.g. 1.28.0]
- Operating System: [e.g. macOS 13.0, Ubuntu 22.04]

**Error messages**
Please include any error messages or logs from:
- Terraform output
- AWS CloudWatch logs
- kubectl logs
- AWS Console errors

```
Paste error messages here
```

**Configuration details**
Please provide your configuration (remove any sensitive information):

```hcl
# Paste your sanitized terraform configuration here
module "eks_clickhouse" {
  source = "github.com/Altinity/terraform-aws-eks-clickhouse"

  # Your configuration...
}
```

**Terraform plan/apply output**
If applicable, include the relevant parts of `terraform plan` or `terraform apply` output (sanitized):

```
Paste sanitized terraform output here
```

**Steps to reproduce**
1. Go to '...'
2. Run command '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
A clear and concise description of what actually happened.

**Additional context**
Add any other context about the problem here, such as:
- AWS region and availability zones used
- VPC/networking setup details
- EKS cluster configuration
- ClickHouse cluster configuration
- IAM permissions or restrictions
- Any custom configurations or modifications
- Screenshots (if applicable)

**Workaround**
If you found a temporary workaround, please describe it here.
