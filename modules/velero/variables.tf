variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "ARN of the OIDC provider for the cluster"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Velero"
  type        = string
  default     = "velero"
}

variable "service_account_name" {
  description = "Name of the Velero service account"
  type        = string
  default     = "velero-server"
}

variable "role_name" {
  description = "Name of the IAM role for Velero"
  type        = string
  default     = "velero-server-role"
}

variable "policy_name" {
  description = "Name of the IAM policy for Velero"
  type        = string
  default     = "velero-server-policy"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
