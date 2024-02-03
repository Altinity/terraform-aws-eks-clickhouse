output "cluster_arn" {
  value       = aws_eks_cluster.this.arn
  description = "The Amazon Resource Name (ARN) of the cluster"
}

output "cluster_name" {
  value       = aws_eks_cluster.this.name
  description = "The name of the cluster"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.this.endpoint
  description = "The endpoint for your Kubernetes API server"
}
