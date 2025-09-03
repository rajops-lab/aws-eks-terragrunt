# ========================================
# SIMPLIFIED EKS ADDONS OUTPUTS
# ========================================
# Essential outputs for easy integration

# ========================================
# Core Addon Status (Most Used)
# ========================================
output "addons_deployed" {
  description = "Map of core addons and their deployment status"
  value = {
    vpc_cni        = var.enabled && var.enable_vpc_cni
    coredns        = var.enabled && var.enable_coredns && var.node_groups_ready
    kube_proxy     = var.enabled && var.enable_kube_proxy
    ebs_csi_driver = var.enabled && var.enable_ebs_csi_driver && var.node_groups_ready
    alb_controller = var.enabled && var.enable_aws_load_balancer_controller
    metrics_server = var.enabled && var.enable_metrics_server
  }
}

# ========================================
# IRSA Role ARNs (For other modules)
# ========================================
output "irsa_role_arns" {
  description = "ARNs of IRSA roles for integration with other modules"
  value = {
    # COMMENTED OUT: Problematic indexing into empty tuple when create_irsa_roles=false
    # vpc_cni_role = var.enabled && var.create_irsa_roles && var.enable_vpc_cni ? aws_iam_role.vpc_cni_irsa[0].arn : null
    # ebs_csi_role = var.enabled && var.create_irsa_roles && var.enable_ebs_csi_driver ? aws_iam_role.ebs_csi_irsa[0].arn : null
    # alb_controller_role = var.enabled && var.create_irsa_roles && var.enable_aws_load_balancer_controller ? aws_iam_role.aws_load_balancer_controller_irsa[0].arn : null
    
    # FIXED: Added length check to prevent "Invalid index" error when resources don't exist
    vpc_cni_role = var.enabled && var.create_irsa_roles && var.enable_vpc_cni && length(aws_iam_role.vpc_cni_irsa) > 0 ? aws_iam_role.vpc_cni_irsa[0].arn : null
    ebs_csi_role = var.enabled && var.create_irsa_roles && var.enable_ebs_csi_driver && length(aws_iam_role.ebs_csi_irsa) > 0 ? aws_iam_role.ebs_csi_irsa[0].arn : null
    alb_controller_role = var.enabled && var.create_irsa_roles && var.enable_aws_load_balancer_controller && length(aws_iam_role.aws_load_balancer_controller_irsa) > 0 ? aws_iam_role.aws_load_balancer_controller_irsa[0].arn : null
  }
}

# ========================================
# Addon ARNs (For dependencies)
# ========================================
output "addon_arns" {
  description = "ARNs of deployed EKS addons"
  value = {
    vpc_cni        = var.enabled && var.enable_vpc_cni ? aws_eks_addon.vpc_cni[0].arn : null
    coredns        = var.enabled && var.enable_coredns && var.node_groups_ready ? aws_eks_addon.coredns[0].arn : null
    kube_proxy     = var.enabled && var.enable_kube_proxy ? aws_eks_addon.kube_proxy[0].arn : null
    ebs_csi_driver = var.enabled && var.enable_ebs_csi_driver && var.node_groups_ready ? aws_eks_addon.ebs_csi_driver[0].arn : null
  }
}

# ========================================
# Simple Summary
# ========================================
output "deployment_summary" {
  description = "Simple deployment summary"
  value = {
    cluster_name     = var.cluster_name
    addons_enabled   = var.enabled
    core_addons_count = length([for k, v in {
      vpc_cni        = var.enabled && var.enable_vpc_cni,
      coredns        = var.enabled && var.enable_coredns && var.node_groups_ready,
      kube_proxy     = var.enabled && var.enable_kube_proxy,
      ebs_csi_driver = var.enabled && var.enable_ebs_csi_driver && var.node_groups_ready
    } : k if v])
    irsa_roles_created = var.enabled && var.create_irsa_roles
    node_groups_ready  = var.node_groups_ready
  }
}
