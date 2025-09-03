# ========================================
# EKS DEPLOYMENT MODULE OUTPUTS
# ========================================

# ========================================
# VPC OUTPUTS
# ========================================
output "vpc_id" {
  description = "VPC ID used for EKS cluster"
  value       = try(module.vpc_data[0].vpc_id, var.vpc_id)
}

output "private_subnet_ids" {
  description = "Private subnet IDs used for EKS cluster"
  value       = try(module.vpc_data[0].private_subnet_ids, [])
}

output "public_subnet_ids" {
  description = "Public subnet IDs discovered"
  value       = try(module.vpc_data[0].public_subnet_ids, [])
}

# ========================================
# BASTION HOST OUTPUTS (DISABLED)
# ========================================
# Note: Bastion outputs commented out since module is disabled
# output "bastion_instance_id" {
#   description = "Bastion host instance ID"
#   value       = try(module.bastion[0].bastion_instance_id, null)
# }
# 
# output "bastion_public_ip" {
#   description = "Bastion host public IP address"
#   value       = try(module.bastion[0].bastion_public_ip, null)
# }
# 
# output "bastion_private_ip" {
#   description = "Bastion host private IP address"
#   value       = try(module.bastion[0].bastion_private_ip, null)
# }
# 
# output "bastion_security_group_id" {
#   description = "Bastion host security group ID"
#   value       = try(module.bastion[0].bastion_security_group_id, null)
# }

# ========================================
# EKS CLUSTER OUTPUTS
# ========================================
output "cluster_id" {
  description = "EKS cluster ID"
  value       = try(module.eks_cluster[0].cluster_id, null)
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint"
  value       = try(module.eks_cluster[0].cluster_endpoint, null)
}

output "cluster_version" {
  description = "EKS cluster version"
  value       = var.cluster_version
}

output "cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = try(module.eks_cluster[0].cluster_platform_version, null)
}

output "cluster_status" {
  description = "EKS cluster status"
  value       = try(module.eks_cluster[0].cluster_status, null)
}

output "cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = try(module.eks_cluster[0].cluster_security_group_id, null)
}

output "cluster_ca_certificate" {
  description = "EKS cluster certificate authority data"
  value       = try(module.eks_cluster[0].cluster_certificate_authority, null)
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for the EKS cluster"
  value       = try(module.eks_cluster[0].oidc_provider_arn, null)
}

# ========================================
# NODE GROUP OUTPUTS
# ========================================
output "node_group_name" {
  description = "EKS node group name"
  value       = try(module.eks_nodegroup[0].node_group_name, null)
}

output "node_group_arn" {
  description = "EKS node group ARN"
  value       = try(module.eks_nodegroup[0].node_group_arn, null)
}

output "node_group_status" {
  description = "EKS node group status"
  value       = try(module.eks_nodegroup[0].node_group_status, null)
}

output "node_group_capacity_type" {
  description = "EKS node group capacity type"
  value       = try(module.eks_nodegroup[0].node_group_capacity_type, null)
}

output "node_group_instance_types" {
  description = "EKS node group instance types"
  value       = try(module.eks_nodegroup[0].node_group_instance_types, null)
}

# ========================================
# EKS ADDONS OUTPUTS
# ========================================
output "eks_addons" {
  description = "EKS addons configuration"
  value = try({
    vpc_cni_addon_arn        = module.eks_addons[0].vpc_cni_addon_arn
    coredns_addon_arn        = module.eks_addons[0].coredns_addon_arn
    kube_proxy_addon_arn     = module.eks_addons[0].kube_proxy_addon_arn
    ebs_csi_driver_addon_arn = module.eks_addons[0].ebs_csi_driver_addon_arn
  }, {})
}

# ========================================
# MONITORING OUTPUTS
# ========================================
output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = try(module.monitoring[0].monitoring_namespace, null)
}

output "grafana_service_name" {
  description = "Grafana service name"
  value       = try(module.monitoring[0].grafana_service_name, null)
}

output "prometheus_service_name" {
  description = "Prometheus service name"
  value       = try(module.monitoring[0].prometheus_service_name, null)
}

# ========================================
# STAGE STATUS OUTPUTS
# ========================================
output "deployment_stages" {
  description = "Status of deployment stages"
  value = {
    stage_01_vpc        = var.enable_stage_01_vpc ? "Enabled" : "Disabled"
    stage_02_bastion    = var.enable_bastion ? "Enabled" : "Disabled"
    stage_03_cluster    = (var.enable_stage_02_cluster || var.enable_stage_03_cluster) ? "Enabled" : "Disabled"
    stage_04_nodes      = (var.enable_stage_03_nodes || var.enable_stage_04_nodes) ? "Enabled" : "Disabled"
    stage_05_addons     = (var.enable_stage_04_addons || var.enable_stage_05_addons) ? "Enabled" : "Disabled"
    stage_06_monitoring = (var.enable_stage_05_monitoring || var.enable_stage_06_monitoring) ? "Enabled" : "Disabled"
  }
}

# ========================================
# CONNECTION INFORMATION
# ========================================
output "connection_info" {
  description = "Connection information for accessing the EKS cluster"
  value = {
    cluster_name     = local.cluster_name
    cluster_endpoint = try(module.eks_cluster[0].cluster_endpoint, "Not deployed")
    region          = var.region
    bastion_ip      = "Disabled (module path issues)"
    kubectl_config  = "aws eks update-kubeconfig --region ${var.region} --name ${local.cluster_name}"
  }
}

# ========================================
# DEPLOYMENT SUMMARY
# ========================================
output "deployment_summary" {
  description = "Summary of the EKS deployment"
  value = {
    environment     = var.environment
    cluster_name    = local.cluster_name
    cluster_version = var.cluster_version
    region         = var.region
    vpc_id         = try(module.vpc_data[0].vpc_id, var.vpc_id)
    node_count     = "${var.node_min_size_general}-${var.node_max_size_general} (desired: ${var.node_desired_size_general})"
    instance_types = join(", ", var.node_instance_types_general)
    capacity_type  = var.capacity_type
    monitoring     = (var.enable_stage_05_monitoring || var.enable_stage_06_monitoring) ? "Enabled" : "Disabled"
    bastion_host   = var.enable_bastion ? "Enabled" : "Disabled"
    encryption     = var.enable_cluster_encryption ? "Enabled" : "Disabled"
    deployment_time = timestamp()
  }
}
