# ============================================================================
# Bastion Host Module - Flexible Deployment
# Supports both creating new bastion instances and referencing existing ones
# ============================================================================

# PROVIDER VERSIONS NOW MANAGED CENTRALLY BY TERRAGRUNT ROOT CONFIG
# terraform {
#   required_version = ">= 1.3"
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 6.0"
#     }
#   }
# }

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Determine whether to create a new bastion or use existing one
  create_new_bastion = var.create_new_bastion
  
  # Common tags for all resources
  common_tags = merge(var.common_tags, {
    Component   = "bastion-host"
    ManagedBy   = "terraform"
    Purpose     = "eks-private-access"
  })

  # Bastion connection details
  bastion_instance_id = local.create_new_bastion ? module.new_bastion[0].bastion_instance_id : var.existing_bastion_instance_id
  bastion_private_ip  = local.create_new_bastion ? module.new_bastion[0].bastion_private_ip : var.existing_bastion_private_ip
  bastion_public_ip   = local.create_new_bastion ? module.new_bastion[0].bastion_public_ip : var.existing_bastion_public_ip
}

# ============================================================================
# New Bastion Host Creation (Conditional)
# ============================================================================

module "new_bastion" {
  count  = local.create_new_bastion ? 1 : 0
  source = "./bastion-instance"  # Use local submodule instead of archive

  # Enable the module
  enabled = true

  # Basic Configuration
  cluster_name = var.cluster_name
  bastion_os   = var.bastion_os
  bastion_ami  = var.bastion_ami

  # Instance Configuration
  bastion_instance_type = var.instance_type

  # Network Configuration
  vpc_id    = var.vpc_id
  vpc_cidr  = var.vpc_cidr
  subnet_id = var.subnet_id

  # Security Configuration
  bastion_ssh_ingress_cidrs = var.allowed_cidr_blocks

  # EKS Integration
  kubectl_version = var.kubectl_version
  aws_region      = var.region

  # Tagging
  common_tags = local.common_tags
}

# ============================================================================
# Data Sources for Existing Bastion (Conditional)
# ============================================================================

# Get current AWS account ID and caller identity
data "aws_caller_identity" "current" {}

# Get subnet information for availability zone
data "aws_subnet" "bastion_subnet" {
  count = local.create_new_bastion ? 1 : 0
  id    = var.subnet_id
}

# Get information about existing bastion instance
data "aws_instance" "existing_bastion" {
  count       = local.create_new_bastion ? 0 : 1
  instance_id = var.existing_bastion_instance_id

  # Only fetch if we're not creating a new one
  depends_on = []
}

# Get security group of existing bastion for reference
data "aws_security_groups" "existing_bastion_sg" {
  count = local.create_new_bastion ? 0 : 1
  
  filter {
    name   = "group-name"
    values = ["${var.bastion_name}-*", "*bastion*", "*${var.cluster_name}*"]
  }

  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# ============================================================================
# Common Security Group Rules for EKS Access
# ============================================================================

# Additional security group for EKS cluster communication
resource "aws_security_group" "bastion_eks_access" {
  count       = var.create_eks_access_sg ? 1 : 0
  name_prefix = "${var.bastion_name}-eks-access-"
  description = "Additional security group for bastion EKS access"
  vpc_id      = var.vpc_id

  # Outbound rules for EKS API server access
  egress {
    description = "EKS API Server (HTTPS)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules for EKS nodes communication
  egress {
    description = "EKS Node Communication"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS resolution
  egress {
    description = "DNS"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.bastion_name}-eks-access-sg"
  })
}

# Note: Network interface attachment is not supported by the underlying module
# The EKS access security group will be created but not attached automatically
# This can be done manually or through instance modification

# ============================================================================
# SSM Documents for Bastion Management
# ============================================================================

# SSM Document for EKS configuration validation
resource "aws_ssm_document" "validate_eks_access" {
  count           = var.create_ssm_documents ? 1 : 0
  name            = "${var.bastion_name}-validate-eks-access"
  document_type   = "Command"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "2.2"
    description   = "Validate EKS cluster access from bastion host"
    parameters = {
      clusterName = {
        type        = "String"
        description = "EKS Cluster Name"
        default     = var.cluster_name
      }
      region = {
        type        = "String"
        description = "AWS Region"
        default     = var.region
      }
    }
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "validateEKSAccess"
        inputs = {
          timeoutSeconds = "300"
          runCommand = [
            "#!/bin/bash",
            "set -e",
            "echo 'Validating EKS cluster access...'",
            "export AWS_DEFAULT_REGION={{ region }}",
            "export PATH=$PATH:/usr/local/bin",
            "",
            "# Validate AWS CLI access",
            "echo 'Checking AWS credentials...'",
            "aws sts get-caller-identity",
            "",
            "# Validate EKS cluster access",
            "echo 'Checking EKS cluster status...'",
            "aws eks describe-cluster --name {{ clusterName }} --region {{ region }} --query 'cluster.status'",
            "",
            "# Update kubeconfig",
            "echo 'Updating kubeconfig...'",
            "aws eks update-kubeconfig --region {{ region }} --name {{ clusterName }}",
            "",
            "# Test cluster connectivity",
            "echo 'Testing cluster connectivity...'",
            "kubectl cluster-info",
            "kubectl get nodes",
            "kubectl get pods -n kube-system",
            "",
            "echo 'EKS access validation completed successfully!'"
          ]
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.bastion_name}-validate-eks-access"
  })
}

# SSM Document for bastion maintenance
resource "aws_ssm_document" "bastion_maintenance" {
  count           = var.create_ssm_documents ? 1 : 0
  name            = "${var.bastion_name}-maintenance"
  document_type   = "Command"
  document_format = "YAML"

  content = yamlencode({
    schemaVersion = "2.2"
    description   = "Perform maintenance tasks on bastion host"
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "maintenanceTasks"
        inputs = {
          timeoutSeconds = "600"
          runCommand = [
            "#!/bin/bash",
            "set -e",
            "echo 'Starting bastion maintenance tasks...'",
            "",
            "# Update system packages based on OS",
            "if [ -f /etc/ubuntu-release ] || [ -f /etc/debian_version ]; then",
            "    echo 'Updating Ubuntu/Debian packages...'",
            "    apt-get update && apt-get upgrade -y",
            "    apt-get autoremove -y",
            "    apt-get autoclean",
            "elif [ -f /etc/redhat-release ] || [ -f /etc/amazon-linux-release ]; then",
            "    echo 'Updating RHEL/Amazon Linux packages...'",
            "    yum update -y",
            "    yum clean all",
            "fi",
            "",
            "# Update kubectl to latest version",
            "echo 'Checking kubectl version...'",
            "kubectl version --client",
            "",
            "# Update AWS CLI if needed",
            "echo 'Checking AWS CLI version...'",
            "aws --version",
            "",
            "# Clean up old logs",
            "echo 'Cleaning up old log files...'",
            "find /var/log -name '*.log' -mtime +7 -delete 2>/dev/null || true",
            "find /tmp -mtime +7 -delete 2>/dev/null || true",
            "",
            "echo 'Bastion maintenance completed successfully!'"
          ]
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.bastion_name}-maintenance"
  })
}
