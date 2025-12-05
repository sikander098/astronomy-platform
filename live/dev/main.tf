# Dev Environment - Terraform Configuration
# Deploys VPC and EKS cluster for the development environment

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
    key    = "dev/terraform.tfstate"
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
      Environment = "dev"
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

  vpc_cidr         = "10.0.0.0/16"
  environment_name = "dev"
  az_count         = 2
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name    = "astronomy-dev"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  instance_types = ["t3.medium", "t3a.medium"]
  capacity_type  = "ON_DEMAND"  # Using ON_DEMAND for stability

  min_size     = 2
  max_size     = 3
  desired_size = 2
}

# Crossplane Module
module "crossplane" {
  source = "../../modules/crossplane"

  cluster_name              = module.eks.cluster_name
  cluster_oidc_provider_arn = module.eks.oidc_provider_arn
  cluster_oidc_provider_url = module.eks.cluster_oidc_issuer_url

  depends_on = [module.eks]
}
