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
  
  # DRY: Environment defaults with overrides
  environment_defaults = {
    # VPC Configuration
    vpc_name            = "my-manual-vpc"
    vpc_id              = ""
    private_subnet_tags = ["Private", "private"]
    public_subnet_tags  = ["Public", "public"]
    use_name_filter     = true
    validate_network    = true
    
    # Security defaults
    endpoint_private_access = true
    endpoint_public_access  = true
    enable_bastion         = true
    
    # EKS defaults
    cluster_version           = "1.33"
    enable_cluster_encryption = true
    capacity_type            = "ON_DEMAND"
    
    # Addon defaults
    monitoring_namespace = "monitoring"
    
    # Stage defaults
    current_stage = "stage_01_vpc"
  }
  
  # DRY: Environment-specific configurations
  environment_configs = {
    sandbox = {
      cost_optimized     = true
      prevent_destroy    = false
      capacity_type      = "SPOT"
      enable_bastion     = false
      
      # Security - more permissive for development
      endpoint_public_access           = true
      public_access_cidrs              = ["0.0.0.0/0"]
      enable_cluster_encryption        = false
      eks_create_private_access_sg     = false
      eks_private_access_cidrs         = []
      
      # Resources - cost optimized
      node_instance_types = ["t3.small", "t3.medium"]
      node_desired_size   = 1
      node_max_size       = 2
      node_min_size       = 1
      disk_size          = 20
      
      # Monitoring - basic
      enable_monitoring       = false
      enable_prometheus       = false
      enable_kong            = false
      prometheus_storage_size = "20Gi"
      grafana_storage_size   = "5Gi"
      grafana_ingress_enabled = false
      grafana_admin_password = "sandbox-admin-123"
      
      # Tags
      environment_tags = {
        Purpose      = "development-testing"
        CostCenter   = "engineering-sandbox"
        AutoShutdown = "true"
        Criticality  = "low"
      }
    }
    
    qa = {
      cost_optimized  = false
      prevent_destroy = true
      capacity_type   = "ON_DEMAND"
      
      # Security - balanced
      endpoint_public_access           = true
      public_access_cidrs              = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      enable_cluster_encryption        = true
      eks_create_private_access_sg     = true
      eks_private_access_cidrs         = ["10.0.0.0/16"]
      
      # Resources - moderate
      node_instance_types = ["t3.medium", "t3.large"]
      node_desired_size   = 3
      node_max_size       = 6
      node_min_size       = 1
      disk_size          = 50
      
      # Monitoring - full stack for testing
      enable_monitoring       = true
      enable_prometheus       = true
      enable_kong            = false
      prometheus_storage_size = "50Gi"
      grafana_storage_size   = "20Gi"
      grafana_ingress_enabled = true
      grafana_admin_password = "qa-admin-secure-2025"
      
      # Tags
      environment_tags = {
        Purpose        = "quality-assurance"
        CostCenter     = "engineering-qa"
        AutoShutdown   = "false"
        Criticality    = "medium"
      }
    }
    
    prod = {
      cost_optimized  = false
      prevent_destroy = true
      capacity_type   = "ON_DEMAND"
      
      # Security - restrictive
      endpoint_public_access           = true
      public_access_cidrs              = ["10.0.0.0/8"]
      enable_cluster_encryption        = true
      eks_create_private_access_sg     = true
      eks_private_access_cidrs         = ["10.0.0.0/16"]
      
      # Resources - high performance
      node_instance_types = ["t3.large", "t3.xlarge"]
      node_desired_size   = 5
      node_max_size       = 10
      node_min_size       = 3
      disk_size          = 100
      
      # Monitoring - comprehensive
      enable_monitoring       = true
      enable_prometheus       = true
      enable_kong            = true
      prometheus_storage_size = "100Gi"
      grafana_storage_size   = "50Gi"
      grafana_ingress_enabled = true
      grafana_admin_password = "prod-admin-ultra-secure-2025"
      
      # Tags
      environment_tags = {
        Purpose        = "production-workloads"
        CostCenter     = "engineering-production"
        AutoShutdown   = "false"
        Criticality    = "high"
        BackupRequired = "true"
      }
    }
  }
  
  # DRY: Get current environment configuration
  current_env_config = local.environment_configs[local.environment]
  
  # DRY: Merged configuration
  merged_config = merge(local.environment_defaults, local.current_env_config)
  
  # DRY: Common tags
  common_tags = merge(
    {
      Project     = local.project_name
      Environment = local.environment
      Owner       = local.owner
      CostCenter  = local.cost_center
      Repository  = "00-eks-terragrunt"
      ManagedBy   = "Terragrunt"
    },
    local.merged_config.environment_tags
  )
}

# Remote state configuration (same as before)
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

# Provider generation (same as before but using centralized versions)
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${local.provider_versions.aws}"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "${local.provider_versions.tls}"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "${local.provider_versions.kubernetes}"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "${local.provider_versions.helm}"
    }
    null = {
      source  = "hashicorp/null"
      version = "${local.provider_versions.null}"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.allowed_account_ids
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terragrunt"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}

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

# DRY: Centralized inputs with environment-specific overrides
inputs = {
  # AWS Configuration
  aws_region          = local.region
  region             = local.region
  allowed_account_ids = local.allowed_account_ids
  
  # Project Configuration
  project_name = local.project_name
  environment  = local.environment
  cluster_name = local.cluster_name
  owner        = local.owner
  cost_center  = local.cost_center
  
  # Tagging
  common_tags = local.common_tags
  
  # DRY: VPC Configuration from merged config
  vpc_name            = local.merged_config.vpc_name
  vpc_id              = local.merged_config.vpc_id
  private_subnet_tags = local.merged_config.private_subnet_tags
  public_subnet_tags  = local.merged_config.public_subnet_tags
  use_name_filter     = local.merged_config.use_name_filter
  validate_network    = local.merged_config.validate_network
  
  # DRY: Security Configuration from merged config
  endpoint_private_access          = local.merged_config.endpoint_private_access
  endpoint_public_access           = local.merged_config.endpoint_public_access
  public_access_cidrs              = local.merged_config.public_access_cidrs
  enable_cluster_encryption        = local.merged_config.enable_cluster_encryption
  eks_create_private_access_sg     = local.merged_config.eks_create_private_access_sg
  eks_private_access_cidrs         = local.merged_config.eks_private_access_cidrs
  
  # DRY: Cluster Configuration from merged config
  cluster_version = local.merged_config.cluster_version
  enable_bastion  = local.merged_config.enable_bastion
  
  # DRY: Node Configuration from merged config
  node_instance_types_general = local.merged_config.node_instance_types
  node_desired_size_general   = local.merged_config.node_desired_size
  node_max_size_general       = local.merged_config.node_max_size
  node_min_size_general       = local.merged_config.node_min_size
  capacity_type              = local.merged_config.capacity_type
  disk_size                  = local.merged_config.disk_size
  
  # DRY: Monitoring Configuration from merged config
  enable_prometheus         = local.merged_config.enable_prometheus
  enable_kong              = local.merged_config.enable_kong
  monitoring_namespace     = local.merged_config.monitoring_namespace
  prometheus_storage_size  = local.merged_config.prometheus_storage_size
  grafana_storage_size     = local.merged_config.grafana_storage_size
  grafana_ingress_enabled  = local.merged_config.grafana_ingress_enabled
  grafana_admin_password   = local.merged_config.grafana_admin_password
  
  # Provider versions
  provider_versions = local.provider_versions
  
  # Placeholder values (populated by module outputs)
  cluster_endpoint      = ""
  cluster_ca_certificate = ""
  oidc_provider_arn     = ""
}
