# ========================================
# SIMPLIFIED IRSA ROLES FOR EKS ADDONS
# ========================================
# Essential IAM roles for service accounts only

# Extract OIDC provider URL from ARN - Handle null case
locals {
  oidc_provider_url = var.oidc_provider_arn != null ? replace(var.oidc_provider_arn, "/^(.*provider/)/", "") : null
  irsa_enabled = var.oidc_provider_arn != null && var.create_irsa_roles
}

# ========================================
# VPC CNI IRSA Role - Network Plugin
# ========================================
resource "aws_iam_role" "vpc_cni_irsa" {
  count = var.enabled && local.irsa_enabled && var.enable_vpc_cni ? 1 : 0
  name  = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-node"
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc-cni-role"
    Type = "IRSA-NetworkingPlugin"
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni_irsa_policy" {
  count      = var.enabled && local.irsa_enabled && var.enable_vpc_cni ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_irsa[0].name
}

# ========================================
# EBS CSI Driver IRSA Role - Persistent Storage
# ========================================
resource "aws_iam_role" "ebs_csi_irsa" {
  count = var.enabled && local.irsa_enabled && var.enable_ebs_csi_driver ? 1 : 0
  name  = "${var.cluster_name}-ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ebs-csi-role"
    Type = "IRSA-StorageDriver"
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_irsa_policy" {
  count      = var.enabled && local.irsa_enabled && var.enable_ebs_csi_driver ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa[0].name
}

# ========================================
# AWS Load Balancer Controller IRSA Role (Optional)
# ========================================
resource "aws_iam_role" "aws_load_balancer_controller_irsa" {
  count = var.enabled && local.irsa_enabled && var.enable_aws_load_balancer_controller ? 1 : 0
  name  = "${var.cluster_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${local.oidc_provider_url}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${local.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-controller-role"
    Type = "IRSA-LoadBalancer"
  })
}

# Essential ALB Controller permissions (simplified)
resource "aws_iam_role_policy" "aws_load_balancer_controller_policy" {
  count = var.enabled && local.irsa_enabled && var.enable_aws_load_balancer_controller ? 1 : 0
  name  = "${var.cluster_name}-alb-controller-policy"
  role  = aws_iam_role.aws_load_balancer_controller_irsa[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:CreateSecurityGroup",
          "ec2:CreateTags",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
      }
    ]
  })
}
