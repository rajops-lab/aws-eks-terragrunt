# EKS Deployment Guide for Harry

## Overview
This guide walks you through the stage-wise deployment of an EKS cluster using Terragrunt in the sandbox environment.

## Prerequisites
1. AWS CLI configured with the role `eks-terra-access-harry`
2. Terragrunt installed (>= 0.50.0)
3. Terraform installed (>= 1.3.0)

## Deployment Architecture

The deployment is organized in stages:
- **Stage 1**: VPC Discovery - Discover existing VPC and subnets
- **Stage 2**: EKS Cluster - Create the EKS control plane
- **Stage 3**: Node Groups - Create worker nodes
- **Stage 4**: EKS Addons - Install core addons (CNI, CoreDNS, etc.)
- **Stage 5**: Monitoring - Deploy monitoring stack

## Stage 1: VPC Discovery (First Stage)

### Current Configuration
The sandbox environment is currently configured for Stage 1 deployment:
```hcl
current_stage = "stage_01_vpc"
```

### What Stage 1 Does
- Discovers your AWS VPC (uses default VPC if no specific VPC is configured)
- Identifies private and public subnets using tags
- Validates network configuration
- Prepares networking information for subsequent stages

### Deploy Stage 1
```bash
# Navigate to sandbox environment
cd environments/sandbox

# Initialize Terragrunt (first time only)
terragrunt init

# Plan the deployment to see what will be created
terragrunt plan

# Apply Stage 1 - VPC Discovery
terragrunt apply
```

### Expected Outputs
After Stage 1 completion, you should see outputs like:
```
Outputs:
vpc_id = "vpc-xxxxxxxxx"
private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
public_subnet_ids = ["subnet-aaaaa", "subnet-bbbbb"]
availability_zones = ["us-east-1a", "us-east-1b"]
discovery_summary = {...}
```

## Stage 2: EKS Cluster

### Update Configuration
Edit `environments/sandbox/terragrunt.hcl`:
```hcl
current_stage = "stage_02_cluster"
```

### Deploy Stage 2
```bash
# Apply Stage 2 - EKS Cluster
terragrunt apply
```

### What Stage 2 Does
- Creates EKS cluster with the discovered network configuration
- Sets up IAM roles and policies for the cluster
- Configures private endpoint access (public access disabled for security)
- Creates necessary security groups

## Stage 3: Node Groups

### Update Configuration
```hcl
current_stage = "stage_03_nodes"
```

### Deploy Stage 3
```bash
terragrunt apply
```

### What Stage 3 Does
- Creates EKS managed node groups
- Configures worker nodes with appropriate instance types
- Sets up auto-scaling configuration

## Stage 4: EKS Addons

### Update Configuration
```hcl
current_stage = "stage_04_addons"
```

### Deploy Stage 4
```bash
terragrunt apply
```

### What Stage 4 Does
- Installs core EKS addons (VPC CNI, CoreDNS, kube-proxy)
- Configures EBS CSI driver for persistent storage

## Stage 5: Monitoring

### Update Configuration
```hcl
current_stage = "stage_05_monitoring"
```

### Deploy Stage 5
```bash
terragrunt apply
```

### What Stage 5 Does
- Deploys monitoring stack
- Sets up CloudWatch integration
- Configures logging and metrics collection

## Customization Options

### VPC Configuration
If you want to use a specific VPC instead of the default:
```hcl
locals {
  vpc_name = "my-custom-vpc"  # Specify VPC name
  # OR
  vpc_id   = "vpc-1234567890"  # Specify VPC ID directly
}
```

### Security Configuration
For production environments, you might want to enable public access with restrictions:
```hcl
inputs = {
  endpoint_public_access = true
  public_access_cidrs   = ["203.0.113.0/24"]  # Your office IP range
}
```

### Instance Types and Sizing
Adjust node group configuration:
```hcl
inputs = {
  node_instance_types = ["t3.large", "t3.xlarge"]
  node_desired_size   = 3
  node_max_size      = 10
  node_min_size      = 2
}
```

## Troubleshooting

### Common Issues

1. **VPC Discovery Fails**
   - Check if your VPC has proper tags (Type: Private/Public for subnets)
   - Verify AWS permissions for the role

2. **State Bucket Issues**
   - Ensure the S3 bucket for Terraform state exists
   - Check DynamoDB table for state locking

3. **Permission Issues**
   - Verify that the `eks-terra-access-harry` role has necessary permissions
   - Check if role assumption is working correctly

### Verification Commands
```bash
# Check Terragrunt version
terragrunt --version

# Validate configuration
terragrunt validate

# Show current state
terragrunt show

# List all resources
terragrunt state list
```

## Cleanup

To destroy the infrastructure (in reverse order):
```bash
# Set current_stage back to earlier stages and apply to remove components
# Or destroy everything at once:
terragrunt destroy
```

## Next Steps After First Stage

1. **Review Outputs**: Check the VPC and subnet information discovered
2. **Update Configuration**: Proceed to Stage 2 by updating `current_stage`
3. **Iterate**: Continue through each stage methodically
4. **Monitor**: Check AWS Console to verify resources are created correctly

## Best Practices

1. **Always Plan First**: Run `terragrunt plan` before `apply`
2. **Stage by Stage**: Don't skip stages, deploy them in order
3. **Review Outputs**: Check each stage's outputs before proceeding
4. **Keep Backups**: Your Terraform state is automatically backed up in S3
5. **Monitor Costs**: Keep an eye on AWS costs, especially for node groups

## Support

If you encounter issues:
1. Check the module documentation in `modules/eks-deployment/`
2. Review Terragrunt logs for detailed error messages
3. Verify AWS permissions and role assumption
4. Check VPC and subnet configurations in AWS Console
