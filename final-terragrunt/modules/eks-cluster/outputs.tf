################################################################################
# EKS Cluster Module Outputs
################################################################################

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = var.enabled ? aws_eks_cluster.cluster[0].endpoint : null
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.enabled ? data.aws_security_group.default[0].id : null
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = var.enabled ? aws_iam_role.cluster[0].arn : null
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = var.enabled ? aws_eks_cluster.cluster[0].certificate_authority[0].data : null
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = var.enabled ? aws_eks_cluster.cluster[0].version : null
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = var.enabled ? aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer : null
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if enabled"
  # Disabled due to IAM tagging permission issue
  # value       = var.enabled ? aws_iam_openid_connect_provider.cluster[0].arn : null
  value       = null
}

output "cluster_name" {
  description = "The name of the cluster"
  value       = var.enabled ? aws_eks_cluster.cluster[0].name : null
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = var.enabled ? aws_eks_cluster.cluster[0].arn : null
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = var.enabled ? aws_eks_cluster.cluster[0].status : null
}

output "private_access_security_group_id" {
  description = "Security group ID for private cluster access"
  value       = var.enabled && var.create_private_access_sg ? aws_security_group.cluster_private_access[0].id : null
}

output "all_security_group_ids" {
  description = "All security group IDs attached to the cluster"
  value = var.enabled ? concat(
    [data.aws_security_group.default[0].id],
    var.create_private_access_sg ? [aws_security_group.cluster_private_access[0].id] : [],
    var.additional_security_group_ids
  ) : []
}

output "cluster_endpoint_access_config" {
  description = "Cluster endpoint access configuration"
  value = var.enabled ? {
    private_access      = aws_eks_cluster.cluster[0].vpc_config[0].endpoint_private_access
    public_access       = aws_eks_cluster.cluster[0].vpc_config[0].endpoint_public_access
    public_access_cidrs = aws_eks_cluster.cluster[0].vpc_config[0].public_access_cidrs
  } : null
}
