# QA Environment - EKS Deployment

## Introduction

The QA environment provides a pre-production testing platform for validating EKS cluster configurations, applications, and infrastructure changes before promoting to production. This environment balances cost efficiency with production-like characteristics to ensure reliable testing outcomes.

### Key Features
- **Cost-optimized** resource allocation for development teams
- **Full monitoring stack** (Prometheus, Grafana) for observability testing
- **Flexible network access** for development and testing workflows
- **Progressive deployment** with 5-stage rollout process
- **Comprehensive documentation** and validation procedures

### Architecture Overview
- **Cluster Name**: `eks-deployment-qa`
- **Region**: `us-east-1`
- **Node Configuration**: 3 nodes (t3.medium/t3.large)
- **Storage**: 50GB EBS volumes
- **Networking**: VPC with public/private subnets
- **Monitoring**: Prometheus (50Gi) + Grafana (20Gi)

## Required User Inputs

Before deploying the QA environment, update the following values in `terragrunt.hcl`:

### Network Configuration
```hcl
# Update VPC settings (choose one approach):

# Option 1: VPC Name-based Discovery (Recommended)
vpc_name = "your-vpc-name-here"     # Replace with your VPC name
vpc_id   = ""                       # Leave empty for auto-discovery

# Option 2: Explicit VPC ID
vpc_name = ""                       # Leave empty when using explicit ID
vpc_id   = "vpc-xxxxxxxxx"         # Replace with your VPC ID
```

### Subnet Identification
```hcl
# Update subnet tags to match your VPC setup
private_subnet_tags = ["Private", "private", "internal"]  # Your private subnet tags
public_subnet_tags  = ["Public", "public", "external"]    # Your public subnet tags
```

### Security Configuration
```hcl
# Update network access control
public_access_cidrs = [
  "10.0.0.0/8",      # Your internal networks
  "172.16.0.0/12",   # Additional private ranges
  "203.0.113.0/24"   # Your office/VPN CIDR (example)
]

# Update EKS private access CIDRs
eks_private_access_cidrs = ["10.0.0.0/16"]  # Your VPC CIDR
```

### Organization Settings
```hcl
# Update AWS account ID
allowed_account_ids = ["123456789012"]  # Replace with your AWS account ID

# Update organizational metadata
owner       = "your-team-name"          # Your team/organization
cost_center = "YourDepartment"          # Your cost center
```

### Monitoring Configuration
```hcl
# Update Grafana settings
grafana_admin_password = "your-secure-password-here"           # Change default password
grafana_ingress_host   = "grafana-qa.yourdomain.com"          # Your domain
```

### Encryption Settings
```hcl
# Update KMS key alias (optional)
kms_key_alias = "alias/qa-eks-your-org-key"  # Your organization naming
```

## Step-by-Step Implementation

### Prerequisites
1. **AWS CLI** configured with appropriate credentials
2. **Terragrunt** >= 0.50.0 installed
3. **Terraform** >= 1.3.0 installed  
4. **kubectl** installed for cluster verification
5. **helm** installed for monitoring validation

### Stage 1: VPC Discovery and Validation

```bash
# Navigate to QA environment
cd /d/iamraj/00-Inbox/00-r0001807/00-eks-terragrunt/environments/qa

# Update terragrunt.hcl with your values (see Required User Inputs above)

# Set stage to VPC discovery
# Edit terragrunt.hcl: current_stage = "stage_01_vpc"

# Validate configuration
terragrunt validate

# Plan VPC discovery
terragrunt plan

# Apply VPC discovery
terragrunt apply
```

**Expected Outcome**: VPC and subnet discovery, security group creation

### Stage 2: EKS Cluster Deployment

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_02_cluster"

# Plan cluster deployment
terragrunt plan

# Apply cluster deployment (takes 10-15 minutes)
terragrunt apply

# Verify cluster creation
aws eks describe-cluster --name eks-deployment-qa --region us-east-1
```

**Expected Outcome**: EKS cluster running with API endpoint accessible

### Stage 3: Node Groups Deployment

```bash
# Update stage configuration  
# Edit terragrunt.hcl: current_stage = "stage_03_nodes"

# Plan node group deployment
terragrunt plan

# Apply node group deployment (takes 5-10 minutes)
terragrunt apply

# Update kubeconfig
aws eks update-kubeconfig --name eks-deployment-qa --region us-east-1

# Verify nodes
kubectl get nodes
```

**Expected Outcome**: 3 worker nodes in Ready state

### Stage 4: EKS Addons Installation

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_04_addons"

# Plan addon installation
terragrunt plan

# Apply addon installation
terragrunt apply

# Verify addons
aws eks describe-addon --cluster-name eks-deployment-qa --addon-name vpc-cni --region us-east-1
aws eks describe-addon --cluster-name eks-deployment-qa --addon-name coredns --region us-east-1
aws eks describe-addon --cluster-name eks-deployment-qa --addon-name kube-proxy --region us-east-1
aws eks describe-addon --cluster-name eks-deployment-qa --addon-name aws-ebs-csi-driver --region us-east-1
```

**Expected Outcome**: All EKS addons active, IRSA roles configured

### Stage 5: Monitoring Stack Deployment

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_05_monitoring"

# Plan monitoring deployment
terragrunt plan

# Apply monitoring deployment
terragrunt apply

# Verify monitoring components
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
```

**Expected Outcome**: Prometheus and Grafana running with persistent storage

## Pre-Deployment Validation

### 1. Environment Validation
```bash
# Check AWS credentials and permissions
aws sts get-caller-identity

# Verify AWS account access
aws iam list-account-aliases

# Check region configuration
aws configure get region
```

### 2. Network Prerequisites
```bash
# Verify VPC exists and is accessible
aws ec2 describe-vpcs --vpc-ids vpc-xxxxxxxxx --region us-east-1

# Check subnet availability
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxxx" --region us-east-1

# Validate internet gateway (for public subnets)
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-xxxxxxxxx" --region us-east-1
```

### 3. Terragrunt Configuration Validation
```bash
# Validate terragrunt syntax
terragrunt validate

# Check dependency graph
terragrunt graph-dependencies

# Dry-run configuration parsing
terragrunt run-all plan --terragrunt-non-interactive --dry-run
```

## Post-Deployment Validation

### 1. Cluster Health Verification
```bash
# Update kubeconfig
aws eks update-kubeconfig --name eks-deployment-qa --region us-east-1

# Verify cluster status
kubectl cluster-info

# Check all nodes are ready
kubectl get nodes -o wide

# Verify system pods
kubectl get pods -n kube-system
```

### 2. Networking Validation
```bash
# Test DNS resolution
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default

# Verify CNI plugin
kubectl get daemonset aws-node -n kube-system

# Test pod-to-pod communication
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- ping 8.8.8.8
```

### 3. Storage Validation
```bash
# Verify EBS CSI driver
kubectl get pods -n kube-system -l app=ebs-csi-controller

# Test PVC creation
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp2
EOF

# Check PVC status
kubectl get pvc test-pvc

# Cleanup test
kubectl delete pvc test-pvc
```

### 4. IRSA (IAM Roles for Service Accounts) Validation
```bash
# Verify OIDC provider
aws eks describe-cluster --name eks-deployment-qa --query "cluster.identity.oidc.issuer" --output text --region us-east-1

# Check IRSA roles
aws iam list-roles --query "Roles[?contains(RoleName, 'eks-deployment-qa')]"

# Verify service account annotations
kubectl get serviceaccount aws-node -n kube-system -o yaml
kubectl get serviceaccount ebs-csi-controller-sa -n kube-system -o yaml
```

### 5. Monitoring Stack Validation
```bash
# Check monitoring namespace
kubectl get ns monitoring

# Verify Prometheus components
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus

# Check Prometheus storage
kubectl get pvc -n monitoring -l app.kubernetes.io/name=prometheus

# Verify Grafana deployment
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Test Grafana access (port-forward method)
kubectl port-forward -n monitoring svc/grafana 3000:80 &

# Access Grafana at http://localhost:3000
# Username: admin
# Password: (value from grafana_admin_password in terragrunt.hcl)
```

### 6. Application Deployment Test
```bash
# Deploy test application
kubectl create deployment nginx-test --image=nginx:latest
kubectl scale deployment nginx-test --replicas=2

# Expose application
kubectl expose deployment nginx-test --port=80 --type=LoadBalancer

# Verify deployment
kubectl get deployment nginx-test
kubectl get pods -l app=nginx-test
kubectl get svc nginx-test

# Cleanup test deployment
kubectl delete deployment nginx-test
kubectl delete service nginx-test
```

## Troubleshooting

### Common Issues and Solutions

#### 1. VPC Discovery Failures
```bash
# Issue: VPC not found by name
# Solution: Check VPC name and tags
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=your-vpc-name"

# Issue: Subnet discovery failures
# Solution: Verify subnet tags match configuration
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxx" --query 'Subnets[*].[SubnetId,Tags[?Key==`Name`].Value|[0]]'
```

#### 2. Cluster Access Issues
```bash
# Issue: kubectl access denied
# Solution: Update kubeconfig and verify IAM permissions
aws eks update-kubeconfig --name eks-deployment-qa --region us-east-1 --alias qa-cluster

# Issue: Cluster endpoint not accessible
# Solution: Check security groups and public access settings
aws eks describe-cluster --name eks-deployment-qa --query "cluster.resourcesVpcConfig" --region us-east-1
```

#### 3. Node Group Problems
```bash
# Issue: Nodes not joining cluster
# Solution: Check IAM node instance profile and security groups
aws eks describe-nodegroup --cluster-name eks-deployment-qa --nodegroup-name general --region us-east-1

# Issue: Nodes in NotReady state
# Solution: Check CNI and system pods
kubectl get pods -n kube-system | grep -E "(aws-node|coredns)"
```

#### 4. Monitoring Issues
```bash
# Issue: Prometheus pods pending
# Solution: Check PVC and storage class
kubectl describe pvc -n monitoring
kubectl get storageclass

# Issue: Grafana access problems
# Solution: Verify service and ingress configuration
kubectl get svc -n monitoring grafana
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana
```

## Cleanup Procedure

### Complete Environment Cleanup
```bash
# Navigate to environment directory
cd /d/iamraj/00-Inbox/00-r0001807/00-eks-terragrunt/environments/qa

# Remove destroy protection (edit terragrunt.hcl)
# Set: prevent_destroy = false

# Destroy infrastructure (reverse order)
terragrunt destroy

# Verify cleanup
aws eks list-clusters --region us-east-1
aws ec2 describe-instances --filters "Name=tag:Environment,Values=qa" --region us-east-1
```

### Selective Component Cleanup
```bash
# Cleanup monitoring only (set current_stage = "stage_04_addons")
terragrunt apply

# Cleanup nodes (set current_stage = "stage_02_cluster") 
terragrunt apply

# Full cleanup
terragrunt destroy
```

## Support and Documentation

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **EKS Module Documentation**: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Terragrunt Documentation**: https://terragrunt.gruntwork.io/docs/

## Security Considerations

1. **Secrets Management**: Never commit passwords or sensitive data to version control
2. **Network Security**: Regularly review and update CIDR access lists
3. **RBAC**: Implement proper Kubernetes role-based access control
4. **Monitoring**: Enable audit logging and monitoring for security events
5. **Updates**: Keep EKS version and addons updated regularly

---

**Environment**: QA | **Last Updated**: 2025-01-03 | **Version**: 1.0
