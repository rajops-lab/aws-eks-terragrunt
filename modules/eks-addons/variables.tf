# ========================================
# SIMPLIFIED EKS ADDONS MODULE VARIABLES
# ========================================
# Essential variables only for easy deployment

# ========================================
# REQUIRED INPUTS
# ========================================
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "EKS cluster Kubernetes version"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA (from EKS cluster)"
  type        = string
}

# ========================================
# OPTIONAL CONFIGURATION
# ========================================
variable "enabled" {
  description = "Whether to deploy EKS addons"
  type        = bool
  default     = true
}

variable "node_groups_ready" {
  description = "Whether node groups are ready (controls some addon dependencies)"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# ========================================
# ADDON ENABLEMENT (Default: Core addons only)
# ========================================
variable "enable_vpc_cni" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "enable_coredns" {
  description = "Enable CoreDNS addon (requires node groups)"
  type        = bool
  default     = true
}

variable "enable_kube_proxy" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver (requires node groups)"
  type        = bool
  default     = true
}

# ========================================
# OPTIONAL CONTROLLERS (Default: Disabled)
# ========================================
variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Enable Kubernetes Metrics Server"
  type        = bool
  default     = false
}

# ========================================
# SIMPLIFIED CONFIGURATION
# ========================================
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "create_irsa_roles" {
  description = "Create IAM roles for service accounts (IRSA)"
  type        = bool
  default     = true
}

variable "addon_resolve_conflicts_on_create" {
  description = "How to resolve conflicts when creating EKS addons"
  type        = string
  default     = "OVERWRITE"
  validation {
    condition     = contains(["OVERWRITE", "PRESERVE"], var.addon_resolve_conflicts_on_create)
    error_message = "addon_resolve_conflicts_on_create must be either OVERWRITE or PRESERVE."
  }
}

variable "addon_resolve_conflicts_on_update" {
  description = "How to resolve conflicts when updating EKS addons"
  type        = string
  default     = "OVERWRITE"
  validation {
    condition     = contains(["OVERWRITE", "PRESERVE"], var.addon_resolve_conflicts_on_update)
    error_message = "addon_resolve_conflicts_on_update must be either OVERWRITE or PRESERVE."
  }
}
