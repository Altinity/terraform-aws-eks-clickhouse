output "eks_node_groups" {
  value = {
    for node_group in aws_eks_node_group.this : node_group.id => {
      id             = node_group.id
      status         = node_group.status
      instance_types = node_group.instance_types
      subnet_ids     = node_group.subnet_ids
    }
  }

  description = "Details of each node group in the EKS cluster."
}

output "eks_cluster" {
  value = {
    id              = aws_eks_cluster.this.id
    arn             = aws_eks_cluster.this.arn
    endpoint        = aws_eks_cluster.this.endpoint
    version         = aws_eks_cluster.this.version
    public_access   = aws_eks_cluster.this.vpc_config[0].endpoint_public_access
    private_access  = aws_eks_cluster.this.vpc_config[0].endpoint_private_access
    public_cidrs    = aws_eks_cluster.this.vpc_config[0].public_access_cidrs
  }

  description = "The EKS cluster details."
}