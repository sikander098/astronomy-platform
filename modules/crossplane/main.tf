# Crossplane Module - Installs Crossplane operator and configures IAM for AWS provider

# Install Crossplane via Helm
resource "helm_release" "crossplane" {
  name             = "crossplane"
  repository       = "https://charts.crossplane.io/stable"
  chart            = "crossplane"
  version          = "1.14.5"
  namespace        = var.namespace
  create_namespace = true

  set {
    name  = "provider.packages[0]"
    value = "xpkg.upbound.io/upbound/provider-aws-rds:v1.1.0"
  }

  # Enable IRSA for the provider
  set {
    name  = "args[0]"
    value = "--enable-environment-configs"
  }
}

# IAM Role for Crossplane AWS Provider (IRSA)
data "aws_iam_policy_document" "crossplane_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_oidc_provider_arn]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(var.cluster_oidc_provider_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.namespace}:provider-aws-rds-*",
        "system:serviceaccount:${var.namespace}:upbound-provider-aws-rds-*",
        "system:serviceaccount:${var.namespace}:provider-aws-ec2-*",
        "system:serviceaccount:${var.namespace}:upbound-provider-family-aws-*"
      ]
    }
  }
}

resource "aws_iam_role" "crossplane_provider" {
  name               = "${var.cluster_name}-crossplane-provider-aws"
  assume_role_policy = data.aws_iam_policy_document.crossplane_trust.json

  tags = {
    ManagedBy = "Terraform"
    Purpose   = "Crossplane AWS Provider"
  }
}

resource "aws_iam_role_policy_attachment" "rds_full" {
  role       = aws_iam_role.crossplane_provider.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_full" {
  role       = aws_iam_role.crossplane_provider.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}
