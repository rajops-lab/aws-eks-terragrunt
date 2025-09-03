################################################################################
# EKS Cluster - Simple and Clean Implementation
################################################################################

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  count = var.enabled ? 1 : 0
  name  = "${var.cluster_name}-cluster-role-v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "cluster_service_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

# Use existing default security group instead of creating new one
# This avoids the ec2:CreateSecurityGroup permission requirement
data "aws_security_group" "default" {
  count = var.enabled ? 1 : 0
  name  = "default"
  vpc_id = var.vpc_id
}

# Additional security group for private EKS access control
resource "aws_security_group" "cluster_private_access" {
  count       = var.enabled && var.create_private_access_sg ? 1 : 0
  name_prefix = "${var.cluster_name}-private-access-"
  description = "Security group for private EKS cluster access"
  vpc_id      = var.vpc_id

  # Allow HTTPS traffic from bastion hosts and private subnets
  ingress {
    description = "HTTPS from bastion and private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_access_cidrs
  }

  # Allow traffic from bastion security groups if provided
  dynamic "ingress" {
    for_each = var.bastion_security_group_ids
    content {
      description     = "HTTPS from bastion security group"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-access-sg"
    Purpose = "eks-private-access"
  })
}

# EKS Cluster
resource "aws_eks_cluster" "cluster" {
  count    = var.enabled ? 1 : 0
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster[0].arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
    security_group_ids      = concat(
      [data.aws_security_group.default[0].id],
      var.create_private_access_sg ? [aws_security_group.cluster_private_access[0].id] : [],
      var.additional_security_group_ids
    )
  }

  # Optional encryption
  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config
    content {
      provider {
        key_arn = encryption_config.value.provider_key_arn
      }
      resources = encryption_config.value.resources
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling
  depends_on = [
    aws_iam_role_policy_attachment.cluster_service_policy,
  ]

  tags = var.tags
}

# OIDC Identity Provider
data "tls_certificate" "cluster" {
  count = var.enabled ? 1 : 0
  url   = aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer
}

# OIDC Provider disabled due to iam:TagOpenIDConnectProvider permission issue
# This is not critical for basic EKS cluster functionality
# Uncomment when proper IAM permissions are available
# 
# resource "aws_iam_openid_connect_provider" "cluster" {
#   count           = var.enabled ? 1 : 0
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
#   url             = aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer
# }

