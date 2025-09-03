################################################################################
# EKS Node Group Module Outputs
################################################################################

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = var.enabled ? aws_eks_node_group.node_group[0].arn : null
}

output "node_group_name" {
  description = "EKS node group name"
  value       = var.enabled ? aws_eks_node_group.node_group[0].node_group_name : null
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = var.enabled ? aws_eks_node_group.node_group[0].status : null
}

output "node_group_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group"
  value       = var.enabled ? aws_eks_node_group.node_group[0].capacity_type : null
}

output "node_group_instance_types" {
  description = "Set of instance types associated with the EKS Node Group"
  value       = var.enabled ? aws_eks_node_group.node_group[0].instance_types : null
}

output "node_group_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  value       = var.enabled ? aws_eks_node_group.node_group[0].ami_type : null
}

output "node_group_version" {
  description = "Kubernetes version of the EKS Node Group"
  value       = var.enabled ? aws_eks_node_group.node_group[0].version : null
}

output "node_role_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group Role"
  value       = var.enabled ? aws_iam_role.node_group[0].arn : null
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = var.enabled && var.use_launch_template ? aws_launch_template.node_group[0].id : null
}

output "launch_template_version" {
  description = "Latest version of the launch template"
  value       = var.enabled && var.use_launch_template ? aws_launch_template.node_group[0].latest_version : null
}
