# VPC & Subnets

This Terraform configuration is setting up foundational networking components within AWS, particularly within a VPC (Virtual Private Cloud). Let's break down each resource:

### AWS VPC (`aws_vpc.this`):
- Creates a new VPC with the specified CIDR block.
- Enables DNS support and DNS hostnames within the VPC, which are important for resolving domain names within the VPC and for AWS resources to communicate effectively.
- Applies tags from `var.tags` for easy identification and management.


### Internet Gateway (`aws_internet_gateway.this`):
- Attaches an internet gateway to the created VPC. This gateway allows communication between the VPC and the internet, enabling resources within the VPC to access or be accessed from the internet.


### Subnets (`aws_subnet.this`):
- Creates a specified number of subnets within the VPC across different availability zones for high availability.
- Each subnet is assigned a CIDR block and an availability zone based on the `var.subnets` variable.
- The `map_public_ip_on_launch` attribute is set to `true`, which means instances launched in these subnets will be assigned a public IP address.

### Route Table (`aws_route_table.this`):
- Defines a route table in the VPC.
- Includes a route that directs all traffic (`0.0.0.0/0`, representing all IPv4 addresses) to the internet gateway, enabling internet access for resources within the VPC.

### Route Table Association (`aws_route_table_association.this`):
- Associates each subnet with the route table. This step is crucial as it applies the routing rules defined in the route table to the subnets.


### VPC Endpoint (`aws_vpc_endpoint.this`):
- Creates a VPC endpoint for AWS S3 service. This is a gateway-type endpoint, which allows resources in the VPC to privately connect to the S3 service without needing to go through the public internet, enhancing security and potentially reducing network costs.
- The endpoint is associated with the route table, integrating it into the VPC's network routing.

> 💡 TLDR; This setup is a common pattern for establishing a network infrastructure in AWS, where a VPC acts as an isolated network environment. Subnets provide further network segmentation, the internet gateway enables internet access, route tables define network routing rules, and VPC endpoints allow secure, private connections to AWS services.