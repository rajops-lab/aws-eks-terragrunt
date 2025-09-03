# Quick Stage Reference for Sandbox Deployment

## Current Stage Configuration
Edit the `current_stage` variable in `terragrunt.hcl` to switch between deployment stages:

## Available Stages

### Stage 1: VPC Discovery (CURRENT)
```hcl
current_stage = "stage_01_vpc"
```
**Purpose**: Discover existing VPC and subnet configuration
**Command**: `terragrunt apply`

### Stage 2: EKS Cluster
```hcl
current_stage = "stage_02_cluster"
```
**Purpose**: Create EKS control plane
**Prerequisites**: Stage 1 completed

### Stage 3: Node Groups
```hcl
current_stage = "stage_03_nodes"
```
**Purpose**: Create worker nodes
**Prerequisites**: Stages 1-2 completed

### Stage 4: EKS Addons
```hcl
current_stage = "stage_04_addons"
```
**Purpose**: Install core EKS addons
**Prerequisites**: Stages 1-3 completed

### Stage 5: Monitoring
```hcl
current_stage = "stage_05_monitoring"
```
**Purpose**: Deploy monitoring stack
**Prerequisites**: Stages 1-4 completed

## Quick Commands

```bash
# Navigate to sandbox
cd environments/sandbox

# Check current configuration
terragrunt show

# Plan deployment
terragrunt plan

# Apply current stage
terragrunt apply

# Check outputs
terragrunt output
```

## Stage Dependencies
Each stage builds upon previous ones:
- Stage 1: ✅ VPC Discovery
- Stage 2: VPC + EKS Cluster
- Stage 3: VPC + EKS + Node Groups  
- Stage 4: VPC + EKS + Nodes + Addons
- Stage 5: VPC + EKS + Nodes + Addons + Monitoring
