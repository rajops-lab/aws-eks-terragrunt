# VPC Data Module Testing Guide

This document provides step-by-step testing instructions for the VPC data module when working with a network team-managed VPC.

## 🎯 Testing Objectives

- Validate VPC discovery works with network team's configuration
- Ensure subnet discovery finds required private/public subnets
- Verify multi-AZ setup meets EKS requirements (≥2 AZs)
- Test network connectivity validation
- Confirm module outputs are correct for EKS consumption

## 📋 Prerequisites

### Before Testing
1. **Get VPC details from network team:**
   - VPC Name tag or VPC ID
   - How private subnets are tagged (e.g., Type=private)
   - How public subnets are tagged (e.g., Type=public)
   - Expected number of AZs

2. **AWS Setup:**
   ```powershell
   # Verify AWS CLI access
   aws sts get-caller-identity
   aws ec2 describe-vpcs --region your-region
  ###  in powershell
   aws ec2 describe-vpcs `
  --region us-east-1 `
  --query "Vpcs[*].{ID:VpcId, Name:Tags[?Key=='Name']|[0].Value}" `
  --output table
#### in shell
aws ec2 describe-vpcs \
  --region us-east-1 \
  --query "Vpcs[*].{ID:VpcId, Name:Tags[?Key=='Name']|[0].Value}" \
  --output table

   ```

3. **Terraform Setup:**
   ```powershell
   # Verify Terraform installation
   terraform version
   # Should show >= 1.6.0
   ```

## 🧪 Phase 1: Basic Validation (Safe - No Resources Created)


### Test 1: Terraform Syntax Validation

```powershell
# Navigate to vpc-data module
cd D:\iamraj\06-Projects\03-terraform-aws-eks-monitoring\modules\vpc-data

# Test syntax
terraform init
terraform validate
```

**Expected Result:** ✅ "Success! The configuration is valid."

### Test 2: Create Test Environment

```powershell
# Create test directory
New-Item -Name "test" -ItemType Directory -Force
cd test

# Create basic test configuration
```

Create `test/main.tf`:
```hcl
# test/main.tf
module "vpc_discovery_test" {
  source = "../"
  
  # REPLACE WITH ACTUAL VALUES FROM NETWORK TEAM:
  vpc_name_tag = "shared-vpc"  # Ask network team for actual name
  
  # Start with basic discovery (no validation)
  validate_network = false
  
  # Default tag patterns (adjust based on network team setup)
  private_subnet_tags = ["private", "Private", "app", "application"]
  public_subnet_tags  = ["public", "Public", "dmz", "web"]
}

# Test outputs
output "discovery_results" {
  description = "VPC discovery test results"
  value = {
    vpc_id           = module.vpc_discovery_test.vpc_id
    vpc_cidr         = module.vpc_discovery_test.vpc_cidr_block
    private_count    = length(module.vpc_discovery_test.private_subnet_ids)
    public_count     = length(module.vpc_discovery_test.public_subnet_ids)
    private_ids      = module.vpc_discovery_test.private_subnet_ids
    public_ids       = module.vpc_discovery_test.public_subnet_ids
    azs              = module.vpc_discovery_test.availability_zones
    az_count         = length(module.vpc_discovery_test.availability_zones)
  }
}

output "eks_readiness" {
  description = "EKS deployment readiness check"
  value = {
    vpc_discovered      = module.vpc_discovery_test.vpc_id != ""
    has_private_subnets = length(module.vpc_discovery_test.private_subnet_ids) >= 2
    has_public_subnets  = length(module.vpc_discovery_test.public_subnet_ids) >= 1
    multi_az_ready     = length(module.vpc_discovery_test.availability_zones) >= 2
    ready_for_eks      = (
      module.vpc_discovery_test.vpc_id != "" &&
      length(module.vpc_discovery_test.private_subnet_ids) >= 2 &&
      length(module.vpc_discovery_test.public_subnet_ids) >= 1 &&
      length(module.vpc_discovery_test.availability_zones) >= 2
    )
  }
}
```

Create `test/terraform.tf`:
```hcl
# test/terraform.tf
terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Replace with your region
}
```

### Test 3: Discovery Plan Test

```powershell
# Initialize test environment
terraform init

# Run discovery plan (safe - no resources created)
terraform plan -out=discovery-test.tfplan

# Review what would be discovered
terraform show discovery-test.tfplan
```

**Expected Result:** Plan shows VPC and subnets found with no errors.

### Test 4: Validate Discovery Results

```powershell
# Apply to see actual discovery results (still safe - data sources only)
terraform apply discovery-test.tfplan

# Review results
terraform output discovery_results
terraform output eks_readiness
```

## 📊 Phase 1 Results Analysis

### ✅ Success Criteria:
```json
{
  "discovery_results": {
    "vpc_id": "vpc-12345678",
    "vpc_cidr": "10.0.0.0/16", 
    "private_count": 3,
    "public_count": 3,
    "private_ids": ["subnet-111", "subnet-222", "subnet-333"],
    "public_ids": ["subnet-444", "subnet-555", "subnet-666"],
    "azs": ["us-east-1a", "us-east-1b", "us-east-1c"],
    "az_count": 3
  },
  "eks_readiness": {
    "vpc_discovered": true,
    "has_private_subnets": true,
    "has_public_subnets": true,
    "multi_az_ready": true,
    "ready_for_eks": true
  }
}
```

### ❌ Common Issues & Fixes:

| Issue | Output Shows | Fix Action |
|-------|--------------|------------|
| VPC not found | `vpc_id = ""` | Check `vpc_name_tag` with network team |
| No private subnets | `private_count = 0` | Try fallback test (Phase 2) |
| No public subnets | `public_count = 0` | Check public subnet tagging with network team |
| Single AZ only | `az_count = 1` | Request multi-AZ setup from network team |

## 🧪 Phase 2: Fallback Testing (If Phase 1 Issues)

### Test 5: Name Pattern Fallback

If tag-based discovery fails, test name patterns:

Create `test/fallback-test.tf`:
```hcl
# test/fallback-test.tf
module "fallback_test" {
  source = "../"
  
  vpc_name_tag    = "shared-vpc"  # Same as before
  use_name_filter = true          # Enable name pattern matching
  
  # Adjust patterns based on network team's naming
  private_subnet_name_patterns = [
    "*private*", "*priv*", "*app*", "*application*", "*internal*"
  ]
  public_subnet_name_patterns = [
    "*public*", "*pub*", "*dmz*", "*web*", "*external*"
  ]
  
  validate_network = false
}

output "fallback_results" {
  value = {
    private_count = length(module.fallback_test.private_subnet_ids)
    public_count  = length(module.fallback_test.public_subnet_ids)
    method_used   = "name_pattern"
  }
}
```

```powershell
terraform plan -target=module.fallback_test
terraform apply -target=module.fallback_test
terraform output fallback_results
```

## 🧪 Phase 3: Network Connectivity Validation

### Test 6: Full Network Validation

Once discovery works, test connectivity validation:

Create `test/network-validation-test.tf`:
```hcl
# test/network-validation-test.tf
module "network_validation_test" {
  source = "../"
  
  # Use working configuration from Phase 1
  vpc_name_tag = "shared-vpc"
  
  # Enable full network validation
  validate_network = true
  environment      = "test"
}

output "network_validation_results" {
  value = module.network_validation_test.network_discovery_summary
}
```

```powershell
terraform plan -target=module.network_validation_test
terraform apply -target=module.network_validation_test
terraform output network_validation_results
```

**Expected Output:**
```json
{
  "vpc": {
    "id": "vpc-12345678",
    "cidr": "10.0.0.0/16",
    "tags": { "Environment": "prod", "Name": "shared-vpc" }
  },
  "subnets": {
    "private_count": 3,
    "public_count": 3,
    "availability_zones": ["us-east-1a", "us-east-1b", "us-east-1c"]
  },
  "connectivity": {
    "nat_gateways": ["nat-123"],
    "internet_gateway": "igw-456"
  },
  "validation_passed": true
}
```

## 🧪 Phase 4: Integration Simulation

### Test 7: EKS Module Integration Test

Simulate how EKS module would consume the VPC data:

Create `test/eks-integration-test.tf`:
```hcl
# test/eks-integration-test.tf
module "vpc_for_eks" {
  source = "../"
  
  vpc_name_tag     = "shared-vpc"
  validate_network = true
  environment      = "qa"
}

# Simulate EKS cluster module consumption
locals {
  # This is what EKS cluster module would receive
  eks_cluster_config = {
    vpc_id             = module.vpc_for_eks.vpc_id
    private_subnet_ids = module.vpc_for_eks.private_subnet_ids
    availability_zones = module.vpc_for_eks.availability_zones
  }
  
  # This is what bastion module would receive  
  bastion_config = {
    vpc_id           = module.vpc_for_eks.vpc_id
    public_subnet_id = length(module.vpc_for_eks.public_subnet_ids) > 0 ? 
                       module.vpc_for_eks.public_subnet_ids[0] : null
  }
  
  # Validation checks
  integration_ready = {
    eks_has_subnets    = length(local.eks_cluster_config.private_subnet_ids) >= 2
    bastion_has_subnet = local.bastion_config.public_subnet_id != null
    multi_az_ok        = length(local.eks_cluster_config.availability_zones) >= 2
    all_ready          = (
      local.integration_ready.eks_has_subnets &&
      local.integration_ready.bastion_has_subnet &&
      local.integration_ready.multi_az_ok
    )
  }
}

output "eks_cluster_inputs" {
  description = "What EKS cluster module would receive"
  value = local.eks_cluster_config
}

output "bastion_inputs" {
  description = "What bastion module would receive"
  value = local.bastion_config
}

output "integration_status" {
  description = "Integration readiness status"
  value = local.integration_ready
}
```

```powershell
terraform plan -target=module.vpc_for_eks
terraform apply -target=module.vpc_for_eks

# Review integration readiness
terraform output eks_cluster_inputs
terraform output bastion_inputs  
terraform output integration_status
```

## 📝 Test Results Documentation Template

### Test Results Summary

**Date:** [DATE]
**Tester:** [YOUR_NAME]  
**AWS Region:** [REGION]
**Network Team VPC:** [VPC_NAME]

#### Phase 1: Basic Discovery
- [ ] ✅ Terraform validation passed
- [ ] ✅ VPC discovered successfully  
- [ ] ✅ Private subnets found (count: ___)
- [ ] ✅ Public subnets found (count: ___)
- [ ] ✅ Multi-AZ setup confirmed (AZs: ___)

#### Phase 2: Fallback Testing (if needed)
- [ ] ✅ Name pattern discovery worked
- [ ] ❌ Still issues - needs network team help

#### Phase 3: Network Validation  
- [ ] ✅ Internet Gateway found
- [ ] ✅ NAT Gateway found
- [ ] ✅ All network validation passed

#### Phase 4: Integration Readiness
- [ ] ✅ EKS cluster inputs ready
- [ ] ✅ Bastion inputs ready
- [ ] ✅ Ready for EKS deployment

#### Issues Found:
1. [Issue description] - [Status: Fixed/Pending network team]
2. [Issue description] - [Status: Fixed/Pending network team]

#### Network Team Action Items:
- [ ] [Action item 1]
- [ ] [Action item 2]

## 🚀 Next Steps After Testing

### If All Tests Pass ✅
```powershell
# Clean up test directory
terraform destroy  # In test directory
cd ..
Remove-Item -Recurse test

# Module is ready for EKS integration
Write-Host "✅ VPC Data Module tested and ready for EKS deployment!"
```

### If Tests Fail ❌
1. **Document all issues** in the results template above
2. **Share results** with network team
3. **Request fixes** for any network configuration issues
4. **Retest** after network team updates

## 📧 Network Team Communication Template

```
Subject: VPC Configuration Test Results for EKS Deployment

Hi Network Team,

I've tested VPC discovery for our EKS deployment. Here are the results:

✅ Working:
- VPC discovery: [VPC_ID]
- Private subnets: [COUNT] subnets across [AZ_COUNT] AZs

❌ Issues found:
- [List any issues]

🔧 Requests:
- [List what needs to be fixed]

Full test results attached. Let me know when issues are resolved so I can retest.

Thanks!
[YOUR_NAME]
```

---

## 💡 Quick Test Commands Reference

```powershell
# Quick syntax check
terraform validate

# Quick discovery test  
terraform plan -var="vpc_name_tag=ACTUAL_VPC_NAME"

# Quick results check
terraform apply && terraform output discovery_results

# Clean up
terraform destroy
```

**Ready to test!** Start with Phase 1 and document your results. I'll help analyze them when you share the outputs.
