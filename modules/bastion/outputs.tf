# ============================================================================
# Bastion Host Module Outputs
# ============================================================================

# ============================================================================
# Instance Information Outputs
# ============================================================================

output "instance_id" {
  description = "The ID of the bastion host instance"
  value       = local.bastion_instance_id
}

output "private_ip" {
  description = "The private IP address of the bastion host"
  value       = local.bastion_private_ip
}

output "public_ip" {
  description = "The public IP address of the bastion host"
  value       = local.bastion_public_ip
}

output "instance_arn" {
  description = "The ARN of the bastion host instance"
  value       = local.create_new_bastion ? "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${local.bastion_instance_id}" : data.aws_instance.existing_bastion[0].arn
}

# ============================================================================
# Network Information Outputs
# ============================================================================

output "subnet_id" {
  description = "The subnet ID where the bastion host is deployed"
  value       = var.subnet_id
}

output "vpc_id" {
  description = "The VPC ID where the bastion host is deployed"
  value       = var.vpc_id
}

output "availability_zone" {
  description = "The availability zone of the bastion host"
  value       = local.create_new_bastion ? data.aws_subnet.bastion_subnet[0].availability_zone : data.aws_instance.existing_bastion[0].availability_zone
}

# ============================================================================
# Security Group Outputs
# ============================================================================

output "bastion_security_group_id" {
  description = "The ID of the bastion host security group"
  value       = local.create_new_bastion ? module.new_bastion[0].bastion_security_group_id : null
}

output "eks_access_security_group_id" {
  description = "The ID of the EKS access security group"
  value       = var.create_eks_access_sg ? aws_security_group.bastion_eks_access[0].id : null
}

# ============================================================================
# Connection Information Outputs
# ============================================================================

output "ssh_connection_command" {
  description = "SSH connection command for the bastion host"
  value       = local.create_new_bastion ? module.new_bastion[0].ssh_connection_command : null
}

output "ssm_connection_command" {
  description = "AWS Systems Manager Session Manager connection command"
  value       = "aws ssm start-session --target ${local.bastion_instance_id} --region ${var.region}"
}

# ============================================================================
# Key Pair Information Outputs
# ============================================================================

output "key_pair_name" {
  description = "The name of the key pair used"
  value       = local.create_new_bastion ? module.new_bastion[0].bastion_key_name : var.key_pair_name
}

output "private_key_pem" {
  description = "The private key in PEM format (if key was generated)"
  value       = local.create_new_bastion ? null : null
  sensitive   = true
}

# ============================================================================
# IAM Role Information Outputs
# ============================================================================

output "iam_role_name" {
  description = "The name of the IAM role attached to the bastion host"
  value       = local.create_new_bastion ? null : null
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to the bastion host"
  value       = local.create_new_bastion ? module.new_bastion[0].bastion_iam_role_arn : null
}

output "instance_profile_name" {
  description = "The name of the instance profile attached to the bastion host"
  value       = local.create_new_bastion ? null : null
}

# ============================================================================
# EKS Configuration Outputs
# ============================================================================

output "kubectl_config_command" {
  description = "Command to configure kubectl for the EKS cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = var.cluster_name
}

output "kubectl_version" {
  description = "The version of kubectl installed on the bastion host"
  value       = var.kubectl_version
}

# ============================================================================
# SSM Document Outputs
# ============================================================================

output "validate_eks_access_document_name" {
  description = "The name of the SSM document for validating EKS access"
  value       = var.create_ssm_documents ? aws_ssm_document.validate_eks_access[0].name : null
}

output "maintenance_document_name" {
  description = "The name of the SSM document for bastion maintenance"
  value       = var.create_ssm_documents ? aws_ssm_document.bastion_maintenance[0].name : null
}

# ============================================================================
# SSM Commands for Remote Execution
# ============================================================================

output "validate_eks_command" {
  description = "Command to validate EKS access via SSM"
  value       = var.create_ssm_documents ? "aws ssm send-command --instance-ids ${local.bastion_instance_id} --document-name '${aws_ssm_document.validate_eks_access[0].name}' --region ${var.region}" : null
}

output "maintenance_command" {
  description = "Command to run maintenance tasks via SSM"
  value       = var.create_ssm_documents ? "aws ssm send-command --instance-ids ${local.bastion_instance_id} --document-name '${aws_ssm_document.bastion_maintenance[0].name}' --region ${var.region}" : null
}

# ============================================================================
# Status and Configuration Outputs
# ============================================================================

output "bastion_status" {
  description = "Status information about the bastion deployment"
  value = {
    deployment_mode = local.create_new_bastion ? "new_bastion_created" : "existing_bastion_referenced"
    instance_id     = local.bastion_instance_id
    private_ip      = local.bastion_private_ip
    public_ip       = local.bastion_public_ip
    os_type         = var.bastion_os
    instance_type   = var.instance_type
    cluster_name    = var.cluster_name
    region          = var.region
  }
}

# ============================================================================
# Quick Start Guide Output
# ============================================================================

output "quick_start_guide" {
  description = "Quick start commands and instructions"
  value = {
    ssh_connection    = local.create_new_bastion ? module.new_bastion[0].ssh_connection_command : "SSH connection not available for existing bastion"
    ssm_connection    = "aws ssm start-session --target ${local.bastion_instance_id} --region ${var.region}"
    kubectl_config    = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
    validate_eks      = var.create_ssm_documents ? "aws ssm send-command --instance-ids ${local.bastion_instance_id} --document-name '${aws_ssm_document.validate_eks_access[0].name}' --region ${var.region}" : "SSM documents not created"
    cluster_info      = "kubectl cluster-info"
    get_nodes         = "kubectl get nodes"
  }
}

# ============================================================================
# Tags Output
# ============================================================================

output "tags" {
  description = "Tags applied to the bastion host resources"
  value       = local.common_tags
}
