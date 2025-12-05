output "s3_bucket_name" {
  description = "Name of the S3 bucket for Velero backups"
  value       = aws_s3_bucket.velero.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Velero backups"
  value       = aws_s3_bucket.velero.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role for Velero"
  value       = module.velero_irsa.iam_role_arn
}
