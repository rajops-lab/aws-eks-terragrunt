# ============================================================================
# Bastion Host Module Variables
# ============================================================================

# ============================================================================
# Deployment Control Variables
# ============================================================================

variable "create_new_bastion" {
  description = "Whether to create a new bastion host or use an existing one"
  type        = bool
  default     = true
}

variable "create_eks_access_sg" {
  description = "Whether to create additional security group for EKS access"
  type        = bool
  default     = true
}

variable "create_ssm_documents" {
  description = "Whether to create SSM documents for bastion management"
  type        = bool
  default     = true
}

# ============================================================================
# Basic Configuration Variables
# ============================================================================

variable "bastion_name" {
  description = "Name prefix for the bastion host and related resources"
  type        = string
}

variable "bastion_os" {
  description = "Operating system for the bastion host (ubuntu or amazon-linux)"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = contains(["ubuntu", "amazon-linux"], var.bastion_os)
    error_message = "bastion_os must be either 'ubuntu' or 'amazon-linux'."
  }
}

variable "bastion_ami" {
  description = "AMI ID for the bastion host. If null, will use latest AMI for the specified OS"
  type        = string
  default     = null
}

# ============================================================================
# Instance Configuration Variables
# ============================================================================

variable "instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS Key Pair to use for the bastion host"
  type        = string
  default     = ""
}

# ============================================================================
# Network Configuration Variables
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where the bastion host will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (for security group rules)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_id" {
  description = "Subnet ID where the bastion host will be deployed"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the bastion host"
  type        = string
  default     = ""
}

# ============================================================================
# Security Configuration Variables
# ============================================================================

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
  default     = []
}

variable "ssh_port" {
  description = "SSH port for the bastion host"
  type        = number
  default     = 22
}

# ============================================================================
# EKS Integration Variables
# ============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubectl_version" {
  description = "Version of kubectl to install on the bastion host"
  type        = string
  default     = "1.28.0"
}

variable "region" {
  description = "AWS region"
  type        = string
}

# ============================================================================
# Existing Bastion Configuration (when create_new_bastion = false)
# ============================================================================

variable "existing_bastion_instance_id" {
  description = "Instance ID of existing bastion host (when create_new_bastion = false)"
  type        = string
  default     = ""
}

variable "existing_bastion_private_ip" {
  description = "Private IP of existing bastion host (when create_new_bastion = false)"
  type        = string
  default     = ""
}

variable "existing_bastion_public_ip" {
  description = "Public IP of existing bastion host (when create_new_bastion = false)"
  type        = string
  default     = ""
}

# ============================================================================
# Monitoring and Backup Variables
# ============================================================================

variable "enable_cloudwatch_agent" {
  description = "Whether to install and configure CloudWatch agent"
  type        = bool
  default     = true
}

variable "enable_backup_schedule" {
  description = "Whether to enable automated backup schedule"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# ============================================================================
# Tagging Variables
# ============================================================================

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Optional Override Variables
# ============================================================================

variable "user_data_script" {
  description = "Custom user data script (overrides default)"
  type        = string
  default     = ""
}

variable "additional_security_groups" {
  description = "Additional security group IDs to attach to the bastion host"
  type        = list(string)
  default     = []
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 20
}

variable "root_volume_type" {
  description = "Type of the root volume"
  type        = string
  default     = "gp3"
}

variable "enable_detailed_monitoring" {
  description = "Whether to enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

# ============================================================================
# Environment-Specific Variables
# ============================================================================

variable "environment" {
  description = "Environment name (e.g., prod, sandbox, dev)"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = ""
}
