# Bastion Host Module

This Terraform module provides a flexible bastion host solution for accessing private EKS clusters. It supports both creating new bastion instances and integrating with existing ones, making it suitable for various deployment scenarios.

## Features

- **Flexible Deployment**: Create new bastion instances or reference existing ones
- **Multi-OS Support**: Ubuntu 22.04 LTS and Amazon Linux 2023
- **EKS Integration**: Pre-configured with kubectl, AWS CLI v2, and EKS access tools
- **Security**: Dedicated security groups, IAM roles with least-privilege access
- **Management**: SSM documents for validation, maintenance, and remote execution
- **Monitoring**: CloudWatch integration and automated backup scheduling
- **Rich Tooling**: Includes helm, k9s, docker, and various debugging tools

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Developer     │────│  Bastion Host    │────│  Private EKS    │
│   Workstation   │    │  (Public Subnet) │    │   Cluster       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                               │
                               │
                       ┌──────────────────┐
                       │  SSM/CloudWatch  │
                       │   Management     │
                       └──────────────────┘
```

## Usage

### Creating a New Bastion Host

```hcl
module "bastion" {
  source = "../../modules/bastion"

  # Create new bastion
  create_new_bastion = true
  
  # Basic configuration
  bastion_name = "my-eks-bastion"
  bastion_os   = "ubuntu"
  
  # Instance configuration
  instance_type = "t3.small"
  key_pair_name = "my-key-pair"
  
  # Network configuration
  vpc_id            = "vpc-xxxxxxxxx"
  vpc_cidr          = "10.0.0.0/16"
  subnet_id         = "subnet-xxxxxxxxx"
  availability_zone = "us-west-2a"
  
  # Security
  allowed_cidr_blocks = ["203.0.113.0/24", "198.51.100.0/24"]
  
  # EKS integration
  cluster_name    = "my-eks-cluster"
  kubectl_version = "1.28.0"
  region          = "us-west-2"
  
  # Common tags
  common_tags = {
    Environment = "production"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### Using an Existing Bastion Host

```hcl
module "bastion" {
  source = "../../modules/bastion"

  # Use existing bastion
  create_new_bastion = false
  
  # Existing bastion details
  existing_bastion_instance_id = "i-xxxxxxxxxxxxxxxxx"
  existing_bastion_private_ip  = "10.0.1.100"
  existing_bastion_public_ip   = "203.0.113.10"
  
  # Basic configuration (for reference and SSM documents)
  bastion_name = "existing-bastion"
  
  # Network configuration
  vpc_id   = "vpc-xxxxxxxxx"
  vpc_cidr = "10.0.0.0/16"
  
  # EKS integration
  cluster_name = "my-eks-cluster"
  region       = "us-west-2"
  
  # Optional: Skip creating additional resources
  create_eks_access_sg  = false
  create_ssm_documents  = true
  
  common_tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

## Variables

### Deployment Control

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `create_new_bastion` | Whether to create a new bastion host or use existing | `bool` | `true` |
| `create_eks_access_sg` | Whether to create additional security group for EKS access | `bool` | `true` |
| `create_ssm_documents` | Whether to create SSM documents for management | `bool` | `true` |

### Basic Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `bastion_name` | Name prefix for bastion resources | `string` | **Required** |
| `bastion_os` | Operating system (ubuntu or amazon-linux) | `string` | `"ubuntu"` |
| `bastion_ami` | AMI ID (null for latest) | `string` | `null` |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` |
| `key_pair_name` | AWS Key Pair name | `string` | `""` |

### Network Configuration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `vpc_id` | VPC ID for deployment | `string` | **Required** |
| `vpc_cidr` | VPC CIDR block | `string` | `"10.0.0.0/16"` |
| `subnet_id` | Subnet ID for deployment | `string` | **Required** |
| `allowed_cidr_blocks` | CIDR blocks allowed SSH access | `list(string)` | `[]` |

### EKS Integration

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `cluster_name` | EKS cluster name | `string` | **Required** |
| `kubectl_version` | kubectl version to install | `string` | `"1.28.0"` |
| `region` | AWS region | `string` | **Required** |

### Existing Bastion (when create_new_bastion = false)

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `existing_bastion_instance_id` | Existing bastion instance ID | `string` | `""` |
| `existing_bastion_private_ip` | Existing bastion private IP | `string` | `""` |
| `existing_bastion_public_ip` | Existing bastion public IP | `string` | `""` |

## Outputs

### Instance Information

- `instance_id`: Bastion instance ID
- `private_ip`: Private IP address
- `public_ip`: Public IP address
- `instance_arn`: Instance ARN

### Connection Commands

- `ssh_connection_command`: SSH connection command
- `ssm_connection_command`: SSM Session Manager command
- `kubectl_config_command`: kubectl configuration command

### Management Commands

- `validate_eks_command`: SSM command to validate EKS access
- `maintenance_command`: SSM command for maintenance tasks

### Quick Start Guide

The module outputs a comprehensive quick start guide with all necessary commands:

```hcl
output "quick_start_guide" {
  value = module.bastion.quick_start_guide
}
```

## Operating System Support

### Ubuntu 22.04 LTS

- **Default User**: `ubuntu`
- **Package Manager**: `apt`
- **Features**: Docker, advanced shell aliases, comprehensive tooling
- **User Data**: Enhanced with EKS utility functions and system info scripts

### Amazon Linux 2023

- **Default User**: `ec2-user`
- **Package Manager**: `yum`
- **Features**: Lightweight, AWS-optimized, session manager integration
- **User Data**: Essential tools with robust error handling

## Tools Installed

### Core Tools
- AWS CLI v2
- kubectl (matching cluster version)
- Session Manager plugin

### Ubuntu Additional Tools
- Docker
- Helm
- k9s (Kubernetes management tool)
- Various debugging utilities (htop, tree, jq, vim, git, tcpdump, etc.)

### Development Features
- Pre-configured aliases for kubectl and docker
- EKS utility functions
- Automated kubeconfig setup scripts
- System information and monitoring scripts

## Security Features

### IAM Integration
- Dedicated IAM role with EKS permissions
- SSM access for secure remote management
- CloudWatch logging capabilities

### Network Security
- Dedicated security groups for SSH and EKS access
- Configurable CIDR block restrictions
- VPC-specific communication rules

### Key Management
- Automatic SSH key pair generation (optional)
- Secure private key storage in Terraform state
- Support for existing key pairs

## Management and Monitoring

### SSM Documents

The module creates two SSM documents for remote management:

1. **EKS Access Validation**: Tests cluster connectivity and permissions
2. **Maintenance Tasks**: System updates and cleanup operations

### CloudWatch Integration
- Optional CloudWatch agent installation
- System and application log collection
- Custom metrics and monitoring

### Backup Configuration
- Automated EBS snapshot scheduling
- Configurable retention periods
- Cross-region backup support (optional)

## Best Practices

### For Production Environments
```hcl
# Use existing bastion with minimal new resources
create_new_bastion   = false
create_eks_access_sg = false
create_ssm_documents = true

# Use existing bastion details
existing_bastion_instance_id = "i-prod-bastion-12345"
existing_bastion_private_ip  = "10.0.1.100"
```

### For Sandbox/Development Environments
```hcl
# Create new bastion with full features
create_new_bastion   = true
create_eks_access_sg = true
create_ssm_documents = true

# Enable comprehensive monitoring
enable_cloudwatch_agent = true
enable_backup_schedule  = true
```

### Security Recommendations
- Always specify `allowed_cidr_blocks` to restrict SSH access
- Use SSM Session Manager instead of SSH when possible
- Enable detailed monitoring in production environments
- Regularly update bastion host using maintenance SSM documents

## Troubleshooting

### Common Issues

1. **EKS Access Permission Denied**
   ```bash
   # Run the validation SSM document
   aws ssm send-command --instance-ids i-xxx --document-name 'bastion-validate-eks-access'
   ```

2. **SSH Connection Issues**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids sg-xxx
   ```

3. **kubectl Configuration Issues**
   ```bash
   # Connect via SSM and run configuration script
   aws ssm start-session --target i-xxx
   ./configure-kubectl.sh
   ```

## Examples

See the `examples/` directory for complete deployment scenarios:
- `examples/new-bastion/` - Creating new bastion host
- `examples/existing-bastion/` - Using existing bastion host
- `examples/multi-environment/` - Cross-environment configuration

## Requirements

- Terraform >= 1.3
- AWS Provider >= 5.40
- Appropriate AWS permissions for EC2, IAM, SSM, and EKS resources
