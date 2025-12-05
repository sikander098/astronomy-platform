# Prod Environment - Terraform Configuration
# Deploys VPC and EKS cluster for the production environment

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }

  # S3 backend for remote state storage
  backend "s3" {
    bucket = "sikander-astronomy-tf-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    # Uncomment these for production use:
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "astronomy"
      ManagedBy   = "Terraform"
    }
  }
}

# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr         = "10.1.0.0/16" # Distinct CIDR for Prod
  environment_name = "prod"
  az_count         = 3 # Multi-AZ for High Availability
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "astronomy-prod"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  instance_types = ["t3.medium", "t3.large"]
  capacity_type  = "ON_DEMAND" # Critical for Prod stability

  min_size     = 3
  max_size     = 6
  desired_size = 3
}

# Crossplane Module (Optional for Prod Plan, but good to have)
module "crossplane" {
  source = "../../modules/crossplane"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_oidc_provider_url = module.eks.cluster_oidc_issuer_url
  namespace                 = "crossplane-system"

  depends_on = [module.eks]
}

output "crossplane_role_arn" {
  description = "ARN of the IAM role for Crossplane AWS provider"
  value       = module.crossplane.crossplane_role_arn
}

output "crossplane_role_name" {
  description = "Name of the IAM role for Crossplane AWS provider"
  value       = module.crossplane.crossplane_role_name
}

# Velero Module
module "velero" {
  source = "../../modules/velero"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  
  tags = {
    Environment = "prod"
    Project     = "astronomy"
    ManagedBy   = "Terraform"
  }
}

output "velero_s3_bucket_name" {
  description = "Name of the S3 bucket for Velero backups"
  value       = module.velero.s3_bucket_name
}

output "velero_iam_role_arn" {
  description = "ARN of the IAM role for Velero"
  value       = module.velero.iam_role_arn
}
