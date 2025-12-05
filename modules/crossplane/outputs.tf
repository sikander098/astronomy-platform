output "crossplane_namespace" {
  description = "Namespace where Crossplane is installed"
  value       = var.namespace
}

output "crossplane_role_arn" {
  description = "ARN of the IAM role for Crossplane AWS provider"
  value       = aws_iam_role.crossplane_provider.arn
}

output "crossplane_role_name" {
  description = "Name of the IAM role for Crossplane AWS provider"
  value       = aws_iam_role.crossplane_provider.name
}
