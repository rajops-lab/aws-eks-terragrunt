################################################################################
# EKS Cluster Module Variables
################################################################################

# Control variables
variable "enabled" {
  description = "Whether to create the EKS cluster resources"
  type        = bool
  default     = true
}

# Basic cluster configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.30"
}

# Network configuration
variable "vpc_id" {
  description = "ID of the VPC where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the cluster will be created"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the cluster"
  type        = list(string)
  default     = []
}

# API endpoint configuration
variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from"
  type        = string
  default     = null
}

# Encryption configuration
variable "cluster_encryption_config" {
  description = "Configuration block with encryption configuration for the cluster"
  type = list(object({
    provider_key_arn = string
    resources        = list(string)
  }))
  default = []
}

# Private access security configuration
variable "create_private_access_sg" {
  description = "Whether to create a security group for private cluster access"
  type        = bool
  default     = false
}

variable "private_access_cidrs" {
  description = "List of CIDR blocks allowed private access to the cluster"
  type        = list(string)
  default     = []
}

variable "bastion_security_group_ids" {
  description = "List of bastion security group IDs allowed to access the cluster"
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "List of additional security group IDs to attach to the cluster"
  type        = list(string)
  default     = []
}

# Tags
variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
