# ========================================
# SIMPLIFIED EKS CORE ADDONS
# ========================================
# Essential AWS-managed addons with latest versions

# ========================================
# VPC CNI - Network Interface Plugin (Always install first)
# ========================================
resource "aws_eks_addon" "vpc_cni" {
  count = var.enabled && var.enable_vpc_cni ? 1 : 0

  cluster_name                    = var.cluster_name
  addon_name                      = "vpc-cni"
  # addon_version automatically selected for cluster version
  service_account_role_arn        = var.create_irsa_roles && length(aws_iam_role.vpc_cni_irsa) > 0 ? aws_iam_role.vpc_cni_irsa[0].arn : null
  resolve_conflicts_on_create     = var.addon_resolve_conflicts_on_create
  resolve_conflicts_on_update     = var.addon_resolve_conflicts_on_update

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc-cni"
    Type = "Core-Networking"
  })

}

# ========================================
# kube-proxy - Kubernetes Network Proxy
# ========================================
resource "aws_eks_addon" "kube_proxy" {
  count = var.enabled && var.enable_kube_proxy ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "kube-proxy"
  # addon_version automatically selected for cluster version
  resolve_conflicts_on_create = var.addon_resolve_conflicts_on_create
  resolve_conflicts_on_update = var.addon_resolve_conflicts_on_update

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-kube-proxy"
    Type = "Core-Networking"
  })
}

# ========================================
# CoreDNS - DNS Server (Requires nodes)
# ========================================
resource "aws_eks_addon" "coredns" {
  count = var.enabled && var.enable_coredns && var.node_groups_ready ? 1 : 0

  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  # addon_version automatically selected for cluster version
  resolve_conflicts_on_create = var.addon_resolve_conflicts_on_create
  resolve_conflicts_on_update = var.addon_resolve_conflicts_on_update

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-coredns"
    Type = "Core-DNS"
  })

  # Wait for VPC CNI to be ready
  depends_on = [aws_eks_addon.vpc_cni]
}

# ========================================
# EBS CSI Driver - Persistent Storage (Requires nodes)
# ========================================
resource "aws_eks_addon" "ebs_csi_driver" {
  count = var.enabled && var.enable_ebs_csi_driver && var.node_groups_ready ? 1 : 0

  cluster_name                    = var.cluster_name
  addon_name                      = "aws-ebs-csi-driver"
  # addon_version automatically selected for cluster version
  service_account_role_arn        = var.create_irsa_roles && length(aws_iam_role.ebs_csi_irsa) > 0 ? aws_iam_role.ebs_csi_irsa[0].arn : null
  resolve_conflicts_on_create     = var.addon_resolve_conflicts_on_create
  resolve_conflicts_on_update     = var.addon_resolve_conflicts_on_update

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ebs-csi-driver"
    Type = "Storage"
  })

}
