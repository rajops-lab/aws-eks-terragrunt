################################################################################
# EKS Node Group Module Variables
################################################################################

# Control variables
variable "enabled" {
  description = "Whether to create the EKS node group resources"
  type        = bool
  default     = true
}

# Basic node group configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the node group"
  type        = string
  default     = "1.30"
}

# Network configuration
variable "subnet_ids" {
  description = "List of subnet IDs where the node group will be created"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to nodes (for launch template)"
  type        = list(string)
  default     = []
}

# Instance configuration
variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

# Scaling configuration
variable "desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Maximum number of nodes unavailable at once during a version update"
  type        = number
  default     = 1
}

# Launch Template configuration
variable "use_launch_template" {
  description = "Whether to use a launch template for the node group"
  type        = bool
  default     = false
}

variable "user_data_base64" {
  description = "Base64 encoded user data script for node initialization"
  type        = string
  default     = null
}

# SSH configuration
variable "ssh_key_name" {
  description = "EC2 Key Pair name for SSH access to nodes"
  type        = string
  default     = null
}

variable "ssh_security_group_ids" {
  description = "List of security group IDs allowed to SSH to the nodes"
  type        = list(string)
  default     = []
}

# Node configuration
variable "labels" {
  description = "Key-value map of Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "List of Kubernetes taints to apply to nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# Optional features
variable "enable_ssm_access" {
  description = "Enable AWS Systems Manager (SSM) access for nodes"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
