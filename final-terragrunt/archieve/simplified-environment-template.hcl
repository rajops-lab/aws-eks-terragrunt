# =============================================================================
# SIMPLIFIED ENVIRONMENT CONFIGURATION TEMPLATE
# =============================================================================
# This shows how environments would look with improved DRY implementation

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../modules//eks-deployment"
}

# Environment-specific overrides only
locals {
  # Override current stage for this environment deployment
  current_stage = "stage_04_addons"  # Change as needed for deployment progression
  
  # Optional: Override any root defaults for this specific environment
  # These will automatically merge with root configuration
  environment_overrides = {
    # Example: Override KMS key alias for this environment
    kms_key_alias = "alias/${local.environment}-eks-cluster-key"
    
    # Example: Environment-specific ingress host
    grafana_ingress_host = "grafana-${local.environment}.yourdomain.com"
  }
  
  # Get environment name from directory (provided by root)
  environment = try(basename(dirname(get_terragrunt_dir())), "unknown")
}

# Environment-specific settings
prevent_destroy = true  # Override root default for production

generate "terraform.tfvars" {
  path      = "terraform.tfvars"
  if_exists = "overwrite"
  contents = <<EOF
# Auto-generated for ${local.environment} environment
# Stage: ${local.current_stage}
# Generated: ${timestamp()}
EOF
}

terragrunt_version_constraint = ">= 0.50.0"
terraform_version_constraint  = ">= 1.3.0"

# Minimal inputs - most come from root configuration
inputs = {
  # Override current stage
  current_stage = local.current_stage
  
  # DRY: Stage configuration comes from root
  enable_stage_01_vpc        = local.stage_config_matrix[local.current_stage].enable_stage_01_vpc
  enable_stage_02_cluster    = local.stage_config_matrix[local.current_stage].enable_stage_02_cluster
  enable_stage_03_nodes      = local.stage_config_matrix[local.current_stage].enable_stage_03_nodes
  enable_stage_04_addons     = local.stage_config_matrix[local.current_stage].enable_stage_04_addons
  enable_stage_05_monitoring = local.stage_config_matrix[local.current_stage].enable_stage_05_monitoring
  
  # Environment-specific overrides
  kms_key_alias        = try(local.environment_overrides.kms_key_alias, "")
  grafana_ingress_host = try(local.environment_overrides.grafana_ingress_host, "")
  
  # Dynamic cluster connection (populated by module)
  cluster_endpoint      = ""
  cluster_ca_certificate = ""
  oidc_provider_arn     = ""
}

# =============================================================================
# COMPARISON: BEFORE vs AFTER DRY IMPROVEMENT
# =============================================================================

# BEFORE (Current approach):
# - Each environment has ~250+ lines of configuration
# - Stage matrix duplicated 3 times (75 lines each = 225 lines)
# - Environment configs duplicated with slight variations (~100 lines each)
# - Input mappings repeated in every environment (~50 lines each)
# - Total: ~1000+ lines across 3 environments with lots of duplication

# AFTER (Improved DRY approach):
# - Root configuration: ~350 lines (but handles ALL environments)
# - Each environment: ~50 lines (only overrides and current stage)
# - Total: ~500 lines for same functionality
# - 50% reduction in code duplication
# - Single source of truth for configurations
# - Easier maintenance and updates
