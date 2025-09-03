# =============================================================================
# ROOT TERRAGRUNT CONFIGURATION
# =============================================================================
# This file defines common settings shared across all environments
# It provides:
# - AWS Provider configuration with common settings
# - Remote state configuration for team collaboration
# - Common input variables and tags
# - Shared infrastructure patterns

# Step 1: Define shared locals
# Purpose: Centralize project-wide values that all environments inherit
locals {
  # AWS Region configuration
  region       = "us-east-1"
  region_short = "use1"
  
  # Project configuration - dynamically determined
  project_name = "eks-deployment"
  # Get environment from child directory name (sandbox, qa, prod, etc.)
  environment  = try(basename(dirname(get_terragrunt_dir())), "unknown")
  cluster_name = "${local.project_name}-${local.environment}"
  
  # Team and ownership
  owner       = "platform-team"
  cost_center = "Engineering"
  
  # Account configuration
  allowed_account_ids = ["436123228774"]
  
  # State configuration - dynamic based on role assumption capability
  current_state_config = {
    bucket         = "eks-terraform-state-${local.project_name}-${local.region_short}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    dynamodb_table = "terraform-locks-eks"
  }

  # DRY: Centralized provider versions - single source of truth
  provider_versions = {
    aws        = "~> 6.11"
    helm       = "~> 3.0.2"
    kubernetes = "~> 2.38"
    tls        = "~> 4.1"
    null       = "~> 3.2"
  }

  # DRY: Centralized stage configuration matrix
  # This eliminates duplication across all environments
  stage_config_matrix = {
    stage_01_vpc = {
      enable_stage_01_vpc        = true
      enable_stage_02_cluster    = false
      enable_stage_03_nodes      = false
      enable_stage_04_addons     = false
      enable_stage_05_monitoring = false
    }
    stage_02_cluster = {
      enable_stage_01_vpc        = true
      enable_stage_02_cluster    = true
      enable_stage_03_nodes      = false
      enable_stage_04_addons     = false
      enable_stage_05_monitoring = false
    }
    stage_03_nodes = {
      enable_stage_01_vpc        = true
      enable_stage_02_cluster    = true
      enable_stage_03_nodes      = true
      enable_stage_04_addons     = false
      enable_stage_05_monitoring = false
    }
    stage_04_addons = {
      enable_stage_01_vpc        = true
      enable_stage_02_cluster    = true
      enable_stage_03_nodes      = true
      enable_stage_04_addons     = true
      enable_stage_05_monitoring = false
    }
    stage_05_monitoring = {
      enable_stage_01_vpc        = true
      enable_stage_02_cluster    = true
      enable_stage_03_nodes      = true
      enable_stage_04_addons     = true
      enable_stage_05_monitoring = true
    }
  }



  # Common tags that will be merged with environment-specific tags
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Owner       = local.owner
    CostCenter  = local.cost_center
    Repository  = "00-eks-terragrunt"
    ManagedBy   = "Terragrunt"
  }
  
  # Kubeconfig placeholder - will be populated by EKS cluster outputs
  kubeconfig = {
    host                   = ""
    cluster_ca_certificate = ""
    token                  = ""
  }
}

# Step 2: Configure S3 remote state with role assumption
# Purpose: Keep Terraform state per environment with security controls
# TEMPORARILY COMMENTED OUT DUE TO S3 PERMISSIONS ISSUES
# 
# remote_state {
#   backend = "s3"
#   config = {
#     bucket         = local.current_state_config.bucket
#     key            = local.current_state_config.key
#     region         = local.current_state_config.region
#     encrypt        = true
#     dynamodb_table = local.current_state_config.dynamodb_table
#     
#     # Role assumption for secure state access
#     role_arn     = "arn:aws:iam::436123228774:role/eks-terra-access-harry"
#     session_name = "terragrunt-state-${local.environment}"
#     
#     # S3 bucket security settings
#     skip_bucket_versioning             = false
#     skip_bucket_ssencryption           = false
#     skip_bucket_root_access            = false
#     skip_bucket_enforced_tls           = false
#     skip_bucket_public_access_blocking = false
#     skip_requesting_account_id         = false
#     skip_credentials_validation        = false
#     
#     # S3 bucket tags for management
#     s3_bucket_tags = {
#       Name        = "EKS Terraform State"
#       Environment = "shared"
#       Purpose     = "terraform-state"
#       Project     = local.project_name
#     }
#   }
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite_terragrunt"
#   }
# }

# TEMPORARY: Use local backend for testing
remote_state {
  backend = "local"
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Step 3: Generate comprehensive provider configuration
# Purpose: Ensure consistent provider versions and configuration across all modules
# using latest versions of providers from terraform registry https://registry.terraform.io/ 
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      # Centralized version management: ${local.provider_versions.aws}
      source  = "hashicorp/aws"
      version = "${local.provider_versions.aws}"
    }
    tls = {
      # Centralized version management: ${local.provider_versions.tls}
      source  = "hashicorp/tls"
      version = "${local.provider_versions.tls}"
    }
    kubernetes = {
      # Centralized version management: ${local.provider_versions.kubernetes}
      source  = "hashicorp/kubernetes"
      version = "${local.provider_versions.kubernetes}"
    }
    helm = {
      # Centralized version management: ${local.provider_versions.helm}
      source  = "hashicorp/helm"
      version = "${local.provider_versions.helm}"
    }
    null = {
      # Centralized version management: ${local.provider_versions.null}
      source  = "hashicorp/null"
      version = "${local.provider_versions.null}"
    }
  }
}

# AWS Provider with security and tagging defaults
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.allowed_account_ids
  
  default_tags {
    tags = {
      Project       = var.project_name
      Environment   = var.environment
      ManagedBy     = "Terragrunt"
      Owner         = var.owner
      CostCenter    = var.cost_center
    }
  }
}

# Kubernetes provider - only configure when cluster stages are enabled
# COMMENTED OUT: Old static credential approach that was failing
# %{ if try(var.enable_stage_02_cluster, false) || try(var.enable_stage_03_cluster, false) || try(var.enable_stage_04_addons, false) || try(var.enable_stage_05_addons, false) || try(var.enable_stage_05_monitoring, false) || try(var.enable_stage_06_monitoring, false) ~}
# provider "kubernetes" {
#   host                   = try(var.kubeconfig.host, "")
#   cluster_ca_certificate = try(base64decode(var.kubeconfig.cluster_ca_certificate), "")
#   token                  = try(var.kubeconfig.token, "")
# }
# 
# # Helm provider - only configure when cluster stages are enabled
# provider "helm" {
#   kubernetes {
#     host                   = try(var.kubeconfig.host, "")
#     cluster_ca_certificate = try(base64decode(var.kubeconfig.cluster_ca_certificate), "")
#     token                  = try(var.kubeconfig.token, "")
#   }
# }
# %{ endif ~}

# FIXED: Use AWS EKS authentication for Kubernetes and Helm providers
%{ if try(var.enable_stage_02_cluster, false) || try(var.enable_stage_03_cluster, false) || try(var.enable_stage_04_addons, false) || try(var.enable_stage_05_addons, false) || try(var.enable_stage_05_monitoring, false) || try(var.enable_stage_06_monitoring, false) ~}
provider "kubernetes" {
  host                   = try(var.cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(var.cluster_ca_certificate), "")
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", try(var.cluster_name, ""), "--region", try(var.aws_region, "us-east-1")]
  }
}

# Helm provider - only configure when cluster stages are enabled
provider "helm" {
  kubernetes {
    host                   = try(var.cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(var.cluster_ca_certificate), "")
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", try(var.cluster_name, ""), "--region", try(var.aws_region, "us-east-1")]
    }
  }
}
%{ endif ~}
EOF
}

# Step 4: Common inputs available to all child configurations
# Purpose: Provide consistent configuration across all environments and modules
inputs = {
  # AWS Configuration
  aws_region          = local.region
  allowed_account_ids = local.allowed_account_ids
  
  # Project Configuration
  project_name = local.project_name
  environment  = local.environment
  cluster_name = local.cluster_name
  owner        = local.owner
  cost_center  = local.cost_center
  
  # Tagging
  common_tags = local.common_tags
  
  # EKS Configuration defaults
  cluster_version = "1.31"
  
  # Security defaults - more secure by default
  endpoint_private_access = true
  endpoint_public_access  = false
  public_access_cidrs     = []  # Restrict public access
  
  # Kubernetes configuration
  kubeconfig = local.kubeconfig
  
  # Additional variables needed by modules
  region = local.region
  
  # Provider versions for modules (if needed)
  provider_versions = local.provider_versions
}
