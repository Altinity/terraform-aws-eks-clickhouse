# Contributing to Terraform AWS EKS ClickHouse Module

We welcome contributions to this Terraform module! This document provides guidelines for contributing and includes advanced configuration examples for development purposes.

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Guidelines

- Follow Terraform best practices and conventions
- Update documentation when adding new features
- Ensure all examples are working and tested
- Keep the main README user-focused and move complex examples here
- Use consistent variable naming and descriptions
- Add validation blocks where appropriate
- Follow the existing code structure and module organization

## Code Standards

### Terraform Formatting
- Use `terraform fmt` to format all `.tf` files
- Use consistent indentation (2 spaces)
- Group related variables together with comments

### Variable Naming
- Use descriptive variable names with prefixes (e.g., `eks_`, `clickhouse_`)
- Provide clear descriptions for all variables
- Set appropriate defaults where applicable
- Use validation blocks for complex variables

### Documentation
- Update README.md for user-facing changes
- Document new variables in the variables.tf files
- Include examples for new features
- Update the docs/ directory for architectural changes

## Testing

When contributing changes, please ensure:

- All Terraform configurations are valid (`terraform validate`)
- Examples work as expected (`terraform plan` succeeds)
- No breaking changes without proper versioning
- Documentation is updated accordingly
- Follow the existing code style and conventions

### Local Testing

1. **Validate syntax**:
   ```bash
   terraform validate
   ```

2. **Format code**:
   ```bash
   terraform fmt -recursive
   ```

3. **Test examples**:
   ```bash
   cd examples/default
   terraform init
   terraform plan
   ```

## Module Structure

Understanding the module structure helps when contributing:

```
terraform-aws-eks-clickhouse/
├── main.tf                    # Main module orchestration
├── variables.tf               # Root module variables
├── outputs.tf                 # Root module outputs
├── versions.tf                # Provider version constraints
├── eks/                       # EKS cluster module
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── iam.tf                 # IAM roles and policies
│   ├── vpc.tf                 # VPC and networking
│   └── addons.tf              # EKS addons and autoscaler
├── clickhouse-operator/       # ClickHouse operator module
└── clickhouse-cluster/        # ClickHouse cluster module
```

## Submitting Changes

### Pull Request Process

1. Ensure your branch is up to date with master
2. Run all validation and formatting commands
3. Test your changes with at least one example
4. Update documentation as needed
5. Create a clear pull request description explaining:
   - What changes were made
   - Why they were necessary
   - How to test the changes
   - Any breaking changes

### Commit Messages

Use clear, descriptive commit messages:

```
feat: add support for custom AMI types in node pools
fix: resolve issue with load balancer timeout configuration
docs: update examples with new variable options
refactor: reorganize EKS module structure
```

## Questions and Support

If you have questions about contributing or need help with advanced configurations, please:

1. Check existing [issues](https://github.com/altinity/terraform-aws-eks-clickhouse/issues)
2. Review the [documentation](https://github.com/Altinity/terraform-aws-eks-clickhouse/tree/master/docs)
3. Open a new issue with the provided template
4. Join our [Community Slack](https://altinitydbworkspace.slack.com/join/shared_invite/zt-w6mpotc1-fTz9oYp0VM719DNye9UvrQ)
5. Contact us at [support@altinity.com](mailto:support@altinity.com)

Thank you for contributing to the Terraform AWS EKS ClickHouse module!
