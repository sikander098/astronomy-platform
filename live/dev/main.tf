# Dev Environment - Terraform Configuration
# Deploys VPC and EKS cluster for the development environment

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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
