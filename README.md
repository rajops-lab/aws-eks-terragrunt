# AWS EKS Terragrunt Infrastructure

[![Terraform](https://img.shields.io/badge/Terraform-1.3%2B-blue)](https://terraform.io)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-0.50%2B-green)](https://terragrunt.gruntwork.io)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS%201.33-orange)](https://aws.amazon.com/eks/)

A production-ready, DRY (Don't Repeat Yourself) Terragrunt configuration for deploying AWS EKS clusters with comprehensive monitoring and progressive deployment stages.

## 🚀 Features

- **Multi-Environment Support**: Sandbox, QA, and Production environments
- **Progressive Deployment**: 5-stage deployment process for safety
- **DRY Configuration**: Zero code duplication across environments  
- **Production-Ready**: High availability, security, and monitoring
- **Cost-Optimized**: Environment-specific resource sizing
- **Monitoring Stack**: Prometheus, Grafana, and Kong Gateway
- **IRSA Support**: IAM Roles for Service Accounts configuration
- **Network Security**: VPC integration with public/private subnet support

## 📋 Prerequisites

- [Terraform](https://terraform.io/downloads) >= 1.3.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.50.0  
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for cluster management
- [helm](https://helm.sh/docs/intro/install/) for monitoring stack

## 🏗️ Architecture

### Environment Structure
```
environments/
├── terragrunt.hcl           # Root configuration (DRY)
├── sandbox/                 # Development environment
├── qa/                      # Pre-production environment  
└── prod/                    # Production environment
```

### Module Structure
```
modules/
├── eks-deployment/          # Orchestrator module
├── eks-cluster/            # EKS cluster creation
├── eks-nodegroup/          # Worker node groups
├── eks-addons/             # EKS addons (VPC-CNI, CoreDNS, EBS CSI)
├── monitoring/             # Prometheus & Grafana stack
├── vpc-data/              # VPC discovery utilities
└── bastion/               # Bastion host (optional)
```

## 🚦 Deployment Stages

The infrastructure uses a 5-stage progressive deployment approach:

1. **Stage 1 - VPC Discovery**: Network validation and subnet discovery
2. **Stage 2 - EKS Cluster**: Control plane deployment
3. **Stage 3 - Node Groups**: Worker node deployment  
4. **Stage 4 - EKS Addons**: Essential addons (VPC-CNI, CoreDNS, EBS CSI)
5. **Stage 5 - Monitoring**: Observability stack deployment

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/rajops-lab/aws-eks-terragrunt.git
cd aws-eks-terragrunt
```

### 2. Configure Environment
Navigate to your desired environment and update the configuration:

```bash
cd environments/sandbox
# Edit terragrunt.hcl with your specific values
```

**Required Updates:**
- VPC name or ID
- AWS account ID  
- Subnet tags
- Security CIDR blocks
- Grafana password

### 3. Deploy Infrastructure
```bash
# Stage 1: VPC Discovery
# Set current_stage = "stage_01_vpc" in terragrunt.hcl
terragrunt apply

# Stage 2: EKS Cluster  
# Set current_stage = "stage_02_cluster"
terragrunt apply

# Stage 3: Node Groups
# Set current_stage = "stage_03_nodes"  
terragrunt apply

# Stage 4: EKS Addons
# Set current_stage = "stage_04_addons"
terragrunt apply

# Stage 5: Monitoring
# Set current_stage = "stage_05_monitoring"
terragrunt apply
```

### 4. Access Cluster
```bash
# Update kubeconfig
aws eks update-kubeconfig --name eks-deployment-sandbox --region us-east-1

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

## 🌍 Environment Configurations

### Sandbox Environment
- **Purpose**: Development and testing
- **Resources**: t3.small/medium, 1-2 nodes, SPOT instances
- **Security**: Open access (0.0.0.0/0) for development
- **Monitoring**: Lightweight setup
- **Cost**: Optimized for minimal spend

### QA Environment  
- **Purpose**: Pre-production validation
- **Resources**: t3.medium/large, 3 nodes, ON_DEMAND instances
- **Security**: Restricted CIDR access
- **Monitoring**: Full stack for testing
- **Cost**: Balanced performance/cost

### Production Environment
- **Purpose**: Business-critical workloads
- **Resources**: t3.large/xlarge, 5+ nodes, ON_DEMAND instances  
- **Security**: Highly restricted, encryption enabled
- **Monitoring**: Comprehensive with Kong Gateway
- **Cost**: Performance-optimized

## 📊 DRY Implementation Benefits

| Metric | Before DRY | After DRY | Improvement |
|--------|------------|-----------|-------------|
| **Code Lines** | ~1000+ | ~500 | 50% reduction |
| **Duplicated Code** | 225 lines | 0 lines | 100% elimination |
| **Maintenance Files** | 3 files to update | 1 file to update | 66% reduction |
| **Configuration Drift** | High risk | Zero risk | Risk eliminated |

## 🔧 Usage Examples

### Using Remote Modules
Update your `terragrunt.hcl` to use remote modules:

```hcl
terraform {
  source = "git::https://github.com/rajops-lab/aws-eks-terragrunt.git//modules/eks-deployment?ref=v1.0.0"
}
```

### Custom Environment
Create a new environment by copying an existing one:

```bash
cp -r environments/sandbox environments/staging
# Update staging-specific configurations
```

### Stage Progression
Change deployment stage in `terragrunt.hcl`:

```hcl
locals {
  current_stage = "stage_04_addons"  # Update to progress
}
```

## 🛡️ Security Features

- **Network Isolation**: VPC with public/private subnets
- **Encryption**: EKS envelope encryption with KMS
- **RBAC**: Kubernetes role-based access control  
- **IRSA**: IAM Roles for Service Accounts
- **Security Groups**: Restricted cluster access
- **Audit Logging**: CloudWatch integration

## 📈 Monitoring & Observability  

### Included Components
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Kong Gateway**: API management (production)
- **CloudWatch**: Log aggregation
- **EBS CSI**: Persistent volume support

### Access Monitoring
```bash
# Port forward to Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80

# Access at http://localhost:3000
# Username: admin
# Password: (from terragrunt.hcl configuration)
```

## 🔄 Maintenance

### Update EKS Version
```bash
# Update in root terragrunt.hcl
cluster_version = "1.33"

# Apply to environments
terragrunt apply
```

### Update Provider Versions
All provider versions are centralized in root configuration:

```hcl
provider_versions = {
  aws        = "~> 6.11"
  kubernetes = "~> 2.38"
  helm       = "~> 3.0.2"
}
```

## 🆘 Troubleshooting

### Common Issues

1. **VPC Discovery Failures**
   ```bash
   # Check VPC exists and tags are correct
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=your-vpc-name"
   ```

2. **Cluster Access Issues**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --name cluster-name --region us-east-1
   ```

3. **Node Groups Not Ready**
   ```bash
   # Check node group status
   aws eks describe-nodegroup --cluster-name cluster-name --nodegroup-name general
   ```

### Support
- **Issues**: [GitHub Issues](https://github.com/rajops-lab/aws-eks-terragrunt/issues)
- **Documentation**: See individual module README files
- **Examples**: Check `environments/` directory

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Version Tags

- `v1.0.0` - Initial DRY implementation with full monitoring
- `v1.1.0` - Enhanced security and IRSA support  
- `v1.2.0` - Production-ready monitoring stack

---

**Maintained by**: [RajOps Lab](https://github.com/rajops-lab)  
**Last Updated**: 2025-01-03  
**Terraform Version**: >= 1.3.0  
**Terragrunt Version**: >= 0.50.0
