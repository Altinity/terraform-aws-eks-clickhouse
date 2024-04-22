# VPC & Subnets

> 💡 TL;DR: This setup, utilizing the `terraform-aws-modules/vpc`, is a typical pattern for establishing a network infrastructure in AWS. It includes creating a VPC as an isolated network environment, segmenting it further with subnets, enabling internet access via an internet gateway, defining network routing rules through route tables, and establishing secure, private connections to AWS services with VPC endpoints.

This Terraform module configures essential networking components within AWS, specifically within a VPC (Virtual Private Cloud). It internally uses the [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) to set up all networking-related configurations.

### AWS VPC
- **`module.eks_aws.module.vpc.aws_vpc.this`**: Creates a new VPC with a specified CIDR block, enabling DNS support and DNS hostnames, which are crucial for domain name resolution within the VPC and effective communication across AWS services.
- Tags are applied from the `var.tags` variable for easier identification and management.

### Internet Gateway
- **`module.eks_aws.module.vpc.aws_internet_gateway.this`**: Attaches an internet gateway to the VPC, facilitating communication between the VPC and the internet. This is essential for allowing internet access to and from resources within the VPC.

### NAT Gateway
- **`module.eks_aws.module.vpc.aws_nat_gateway.this`**: Establishes a NAT gateway, utilizing an Elastic IP allocated with `module.eks_aws.module.vpc.aws_eip.nat`. This configuration allows instances in private subnets to access the internet while maintaining their security.
- The `eks_enable_nat_gateway` variable, set to `true` by default, controls the creation of the NAT Gateway. Disabling it means private subnets and subsequently the NAT gateway will not be created, and EKS clusters will operate within public subnets.

### Public & Private Subnets
- **`module.eks_aws.module.vpc.aws_subnet.private[0-N]`** and **`module.eks_aws.module.vpc.aws_subnet.public[0-N]`**: Create multiple public and private subnets across different availability zones for high availability. Private subnets house the EKS cluster by default.
- Each subnet is assigned a unique CIDR block and an availability zone based on the variables `var.eks_availability_zones`, `eks_private_cidr`, and `eks_public_cidr`.
- The `map_public_ip_on_launch` attribute is set to `true` for public subnets, assigning public IP addresses to instances within these subnets. This occurs when the NAT Gateway is disabled.

### Route Tables
- **`module.eks_aws.module.vpc.aws_route_table.public`** and **`module.eks_aws.module.vpc.aws_route_table.private`**: Define route tables in the VPC. The public route table directs traffic through the internet gateway, while the private route table routes traffic via the NAT gateway.

### Route Table Association
- **`module.eks_aws.module.vpc.aws_route_table_association.public[0-N]`** and **`module.eks_aws.module.vpc.aws_route_table_association.private[0-N]`**: Associates each subnet with its respective route table, applying the defined routing rules to the subnets.

### Routes
- **`module.eks_aws.module.vpc.aws_route.public_internet_gateway`**: Establishes a route in the public route table directing all traffic to the internet gateway.
- **`module.eks_aws.module.vpc.aws_route.private_nat_gateway`**: Adds a route in the private route table to direct traffic through the NAT gateway, enabling secure internet access for instances in private subnets.

### Default Network ACL and Security Group
- **`module.eks_aws.module.vpc.aws_default_network_acl.this`**: Sets a default network ACL, which provides a basic level of security by regulating traffic into and out of the associated subnets.
- **`module.eks_aws.module.vpc.aws_default_security_group.this`**: Implements the default security group for the VPC, instantly providing fundamental security settings, such as traffic blocking protocols.
