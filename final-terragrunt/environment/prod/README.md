# Production Environment - EKS Deployment

## Introduction

The Production environment provides a high-availability, secure, and scalable EKS cluster for running business-critical workloads. This environment prioritizes reliability, performance, and security over cost optimization, ensuring mission-critical applications have the resources and resilience they require.

### Key Features
- **High-performance** resource allocation for production workloads
- **Enhanced security** with restricted network access and encryption
- **Full observability** stack (Prometheus, Grafana, Kong Gateway)
- **High availability** with multi-node architecture
- **Production-grade** monitoring and alerting capabilities
- **Comprehensive backup** and disaster recovery considerations

### Architecture Overview
- **Cluster Name**: `eks-deployment-prod`
- **Region**: `us-east-1`
- **Node Configuration**: 5 nodes (t3.large/t3.xlarge)
- **Storage**: 100GB EBS volumes
- **Networking**: VPC with public/private subnets
- **Monitoring**: Prometheus (100Gi) + Grafana (50Gi)
- **API Gateway**: Kong enabled for production traffic

## Required User Inputs

Before deploying the Production environment, update the following values in `terragrunt.hcl`:

### Network Configuration
```hcl
# Update VPC settings (choose one approach):

# Option 1: VPC Name-based Discovery (Recommended)
vpc_name = "your-production-vpc-name"   # Replace with your production VPC name
vpc_id   = ""                           # Leave empty for auto-discovery

# Option 2: Explicit VPC ID
vpc_name = ""                           # Leave empty when using explicit ID
vpc_id   = "vpc-xxxxxxxxx"             # Replace with your production VPC ID
```

### Subnet Identification
```hcl
# Update subnet tags to match your production VPC setup
private_subnet_tags = ["Private", "private", "internal"]  # Your private subnet tags
public_subnet_tags  = ["Public", "public", "external"]    # Your public subnet tags
```

### Security Configuration (Critical for Production)
```hcl
# Update network access control - PRODUCTION RESTRICTED
public_access_cidrs = [
  "10.0.0.0/8"       # Internal corporate networks ONLY
  # "172.16.0.0/12", # Remove broader access ranges for production
  # "YOUR-OFFICE-CIDR/24"  # Add specific office/VPN CIDRs if needed
]

# Update EKS private access CIDRs
eks_private_access_cidrs = ["10.0.0.0/16"]  # Your production VPC CIDR
```

### Organization Settings
```hcl
# Update AWS account ID
allowed_account_ids = ["123456789012"]  # Replace with your production AWS account ID

# Update organizational metadata
owner       = "platform-engineering"    # Production team/organization
cost_center = "Production"              # Production cost center
```

### Monitoring Configuration
```hcl
# Update Grafana settings - CHANGE THESE VALUES
grafana_admin_password = "your-ultra-secure-prod-password"     # MUST change default
grafana_ingress_host   = "grafana.production.yourdomain.com"  # Your production domain
```

### Encryption Settings (Production Required)
```hcl
# Update KMS key alias for production
kms_key_alias = "alias/prod-eks-your-org-key"  # Your organization production key
```

### DNS and Ingress Configuration
```hcl
# Production-specific ingress settings
grafana_ingress_enabled  = true
grafana_ingress_host     = "grafana.production.yourdomain.com"  # Production FQDN
```

## Step-by-Step Implementation

### Prerequisites
1. **AWS CLI** configured with production account credentials
2. **Terragrunt** >= 0.50.0 installed
3. **Terraform** >= 1.3.0 installed
4. **kubectl** installed for cluster verification
5. **helm** installed for monitoring validation
6. **Production Change Control** approval obtained
7. **Backup and Recovery Plan** documented

### Stage 1: VPC Discovery and Validation

```bash
# Navigate to Production environment
cd /d/iamraj/00-Inbox/00-r0001807/00-eks-terragrunt/environments/prod

# CRITICAL: Update terragrunt.hcl with production values
# Review all settings in "Required User Inputs" section above

# Set stage to VPC discovery
# Edit terragrunt.hcl: current_stage = "stage_01_vpc"

# Validate configuration
terragrunt validate

# Plan VPC discovery (review carefully)
terragrunt plan

# Apply VPC discovery
terragrunt apply
```

**Expected Outcome**: Production VPC and subnet discovery, security group creation

### Stage 2: EKS Cluster Deployment

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_02_cluster"

# Plan cluster deployment (review security settings)
terragrunt plan

# Apply cluster deployment (takes 10-15 minutes)
terragrunt apply

# Verify cluster creation
aws eks describe-cluster --name eks-deployment-prod --region us-east-1
```

**Expected Outcome**: Production EKS cluster running with secure API endpoint

### Stage 3: Node Groups Deployment

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_03_nodes"

# Plan node group deployment (review instance sizes)
terragrunt plan

# Apply node group deployment (takes 5-10 minutes)
terragrunt apply

# Update kubeconfig
aws eks update-kubeconfig --name eks-deployment-prod --region us-east-1

# Verify nodes (should see 5 nodes minimum)
kubectl get nodes
kubectl get nodes -o wide
```

**Expected Outcome**: 5 production worker nodes in Ready state

### Stage 4: EKS Addons Installation

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_04_addons"

# Plan addon installation
terragrunt plan

# Apply addon installation
terragrunt apply

# Verify critical addons
aws eks describe-addon --cluster-name eks-deployment-prod --addon-name vpc-cni --region us-east-1
aws eks describe-addon --cluster-name eks-deployment-prod --addon-name coredns --region us-east-1
aws eks describe-addon --cluster-name eks-deployment-prod --addon-name kube-proxy --region us-east-1
aws eks describe-addon --cluster-name eks-deployment-prod --addon-name aws-ebs-csi-driver --region us-east-1
```

**Expected Outcome**: All EKS addons active, production IRSA roles configured

### Stage 5: Monitoring Stack Deployment

```bash
# Update stage configuration
# Edit terragrunt.hcl: current_stage = "stage_05_monitoring"

# Plan monitoring deployment (includes Kong Gateway)
terragrunt plan

# Apply monitoring deployment
terragrunt apply

# Verify production monitoring components
kubectl get pods -n monitoring
kubectl get pvc -n monitoring
kubectl get svc -n monitoring
```

**Expected Outcome**: Prometheus, Grafana, and Kong Gateway running with persistent storage

## Pre-Deployment Validation

### 1. Production Environment Validation
```bash
# Verify production AWS account
aws sts get-caller-identity

# Confirm production account ID matches configuration
aws sts get-caller-identity --query Account --output text

# Verify region is correct
aws configure get region

# Check IAM permissions (production-level access required)
aws iam get-user
aws eks list-clusters --region us-east-1
```

### 2. Network Prerequisites (Production Critical)
```bash
# Verify production VPC exists and is accessible
aws ec2 describe-vpcs --vpc-ids vpc-xxxxxxxxx --region us-east-1

# Check subnet availability (ensure sufficient IPs for production)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxxx" --region us-east-1

# Validate internet gateway for public subnets
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=vpc-xxxxxxxxx" --region us-east-1

# Check NAT gateways for private subnet internet access
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=vpc-xxxxxxxxx" --region us-east-1
```

### 3. Security and Compliance Validation
```bash
# Verify KMS key exists (if specified)
aws kms describe-key --key-id alias/prod-eks-your-org-key --region us-east-1

# Check security group rules and restrictions
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-xxxxxxxxx" --region us-east-1

# Validate IAM roles and policies exist
aws iam list-roles --query "Roles[?contains(RoleName, 'eks-deployment-prod')]"
```

### 4. Production Change Control
```bash
# Document planned changes
terragrunt plan > production-deployment-plan.txt

# Review change plan with stakeholders
# Obtain production deployment approval
# Schedule maintenance window if required
```

## Post-Deployment Validation

### 1. Production Cluster Health Verification
```bash
# Update kubeconfig for production
aws eks update-kubeconfig --name eks-deployment-prod --region us-east-1 --alias prod-cluster

# Verify cluster status and version
kubectl cluster-info
kubectl version --short

# Check all nodes are ready (expect 5+ nodes)
kubectl get nodes -o wide
kubectl describe nodes | grep -E "(Name:|Conditions:)"

# Verify system pods are healthy
kubectl get pods -n kube-system
kubectl get pods -n kube-system | grep -v Running
```

### 2. Production Networking Validation
```bash
# Test DNS resolution from production cluster
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes.default

# Verify CNI plugin is operational
kubectl get daemonset aws-node -n kube-system -o wide

# Test external connectivity
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- ping 8.8.8.8

# Validate service mesh connectivity (if applicable)
kubectl get pods -A | grep -E "(istio|linkerd|consul)"
```

### 3. Production Storage Validation
```bash
# Verify EBS CSI driver is healthy
kubectl get pods -n kube-system -l app=ebs-csi-controller
kubectl get pods -n kube-system -l app=ebs-csi-node

# Test production storage class
kubectl get storageclass
kubectl describe storageclass gp2

# Create production test PVC (larger size)
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prod-test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: gp2
EOF

# Verify PVC binding
kubectl get pvc prod-test-pvc
kubectl describe pvc prod-test-pvc

# Cleanup test
kubectl delete pvc prod-test-pvc
```

### 4. Production IRSA Validation
```bash
# Verify OIDC provider configuration
aws eks describe-cluster --name eks-deployment-prod --query "cluster.identity.oidc.issuer" --output text --region us-east-1

# Check production IRSA roles
aws iam list-roles --query "Roles[?contains(RoleName, 'eks-deployment-prod')]"

# Verify service account annotations for production
kubectl get serviceaccount aws-node -n kube-system -o yaml | grep -A 5 annotations
kubectl get serviceaccount ebs-csi-controller-sa -n kube-system -o yaml | grep -A 5 annotations

# Test EBS CSI functionality with IRSA
kubectl get pods -n kube-system -l app=ebs-csi-controller
kubectl logs -n kube-system -l app=ebs-csi-controller | grep -i "error\|failed" | tail -10
```

### 5. Production Monitoring Stack Validation
```bash
# Check monitoring namespace
kubectl get ns monitoring

# Verify Prometheus components and resource usage
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus -o wide
kubectl top pods -n monitoring -l app.kubernetes.io/name=prometheus

# Check Prometheus storage (100Gi for production)
kubectl get pvc -n monitoring -l app.kubernetes.io/name=prometheus
kubectl describe pvc -n monitoring -l app.kubernetes.io/name=prometheus

# Verify Grafana deployment and resources
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana -o wide
kubectl get pvc -n monitoring -l app.kubernetes.io/name=grafana

# Check Kong Gateway (production API management)
kubectl get pods -n monitoring -l app.kubernetes.io/name=kong
kubectl get svc -n monitoring -l app.kubernetes.io/name=kong

# Test Grafana access (secure production method)
kubectl port-forward -n monitoring svc/grafana 3000:80 &

# Access Grafana at https://localhost:3000 (HTTPS in production)
# Username: admin
# Password: (secure production password from terragrunt.hcl)
```

### 6. Production Application Readiness Test
```bash
# Deploy production test application with resource limits
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prod-nginx-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: prod-nginx-test
  template:
    metadata:
      labels:
        app: prod-nginx-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        ports:
        - containerPort: 80
EOF

# Expose application with LoadBalancer for production
kubectl expose deployment prod-nginx-test --port=80 --type=LoadBalancer --name=prod-nginx-svc

# Verify production deployment
kubectl get deployment prod-nginx-test -o wide
kubectl get pods -l app=prod-nginx-test -o wide
kubectl get svc prod-nginx-svc

# Wait for LoadBalancer external IP
kubectl get svc prod-nginx-svc --watch

# Test application accessibility
EXTERNAL_IP=$(kubectl get svc prod-nginx-svc -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl -I http://$EXTERNAL_IP

# Cleanup production test
kubectl delete deployment prod-nginx-test
kubectl delete service prod-nginx-svc
```

### 7. Production Security Validation
```bash
# Check pod security policies/standards
kubectl get psp 2>/dev/null || echo "Pod Security Policies not configured"
kubectl get pods -A -o jsonpath='{.items[*].spec.securityContext}' | grep -o "runAsNonRoot\|runAsUser" | sort | uniq -c

# Verify network policies (if implemented)
kubectl get networkpolicies -A

# Check RBAC configuration
kubectl auth can-i --list
kubectl get clusterroles | head -20
kubectl get rolebindings -A | head -10
```

## Production Monitoring and Alerting

### Grafana Dashboard Access
```bash
# Production access via ingress (recommended)
# Access: https://grafana.production.yourdomain.com
# Credentials: admin / (production password from terragrunt.hcl)

# Alternative: Port forwarding (temporary access only)
kubectl port-forward -n monitoring svc/grafana 3000:80
# Access: http://localhost:3000
```

### Essential Production Dashboards
1. **Cluster Overview**: Resource utilization, node health
2. **Application Metrics**: Pod performance, replica status
3. **Infrastructure**: EBS volumes, network throughput
4. **Security**: Failed authentication attempts, policy violations

### Production Alerts Configuration
```bash
# View Prometheus alert rules
kubectl get prometheusrules -n monitoring

# Check AlertManager configuration
kubectl get secret -n monitoring | grep alertmanager
kubectl get configmap -n monitoring | grep alertmanager
```

## Troubleshooting Production Issues

### Critical Production Issues

#### 1. Cluster Unavailable
```bash
# Check cluster status
aws eks describe-cluster --name eks-deployment-prod --region us-east-1

# Verify API server endpoint
aws eks describe-cluster --name eks-deployment-prod --query "cluster.endpoint" --region us-east-1

# Check security group rules
aws ec2 describe-security-groups --group-ids $(aws eks describe-cluster --name eks-deployment-prod --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text --region us-east-1) --region us-east-1
```

#### 2. Node Groups Failing
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name eks-deployment-prod --nodegroup-name general --region us-east-1

# Verify Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, 'eks-deployment-prod')]"

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/eks-deployment-prod,Values=owned" --region us-east-1
```

#### 3. Storage Issues
```bash
# Check EBS volumes
kubectl get pv
kubectl get pvc -A

# Verify EBS CSI driver
kubectl logs -n kube-system -l app=ebs-csi-controller --tail=50

# Check storage classes
kubectl get storageclass
kubectl describe storageclass gp2
```

#### 4. Monitoring Stack Issues
```bash
# Prometheus troubleshooting
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus --tail=100
kubectl describe pods -n monitoring -l app.kubernetes.io/name=prometheus

# Grafana troubleshooting
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=100
kubectl describe pods -n monitoring -l app.kubernetes.io/name=grafana

# Kong Gateway issues
kubectl logs -n monitoring -l app.kubernetes.io/name=kong --tail=100
```

## Production Backup and Disaster Recovery

### Cluster Configuration Backup
```bash
# Backup cluster configuration
aws eks describe-cluster --name eks-deployment-prod --region us-east-1 > cluster-backup.json

# Export critical configurations
kubectl get all -A -o yaml > k8s-resources-backup.yaml
kubectl get configmaps -A -o yaml > configmaps-backup.yaml
kubectl get secrets -A -o yaml > secrets-backup.yaml

# Store backups in secure location (S3, etc.)
```

### Persistent Volume Snapshots
```bash
# List all PVCs that need backup
kubectl get pvc -A

# Create EBS snapshots (automated with backup tools)
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/eks-deployment-prod,Values=owned" --region us-east-1
```

## Production Cleanup Procedures

### Emergency Cluster Shutdown
```bash
# Scale down workloads (if needed for emergency)
kubectl scale deployment --replicas=0 --all -A

# Cordon all nodes (prevent scheduling)
kubectl cordon --all

# Drain nodes (safe workload migration)
for node in $(kubectl get nodes --no-headers | awk '{print $1}'); do
  kubectl drain $node --ignore-daemonsets --delete-emptydir-data --force
done
```

### Complete Production Environment Cleanup
```bash
# WARNING: This destroys the entire production environment
# Requires production change control approval

# Navigate to production directory
cd /d/iamraj/00-Inbox/00-r0001807/00-eks-terragrunt/environments/prod

# Remove destroy protection
# Edit terragrunt.hcl: prevent_destroy = false

# Create final backup before destruction
kubectl get all -A -o yaml > final-production-backup.yaml

# Destroy production infrastructure
terragrunt destroy

# Verify complete cleanup
aws eks list-clusters --region us-east-1
aws ec2 describe-instances --filters "Name=tag:Environment,Values=prod" --region us-east-1
```

## Production Support and Escalation

### Support Resources
- **AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Production Runbooks**: (Internal documentation links)

### Escalation Contacts
- **Platform Team**: platform-engineering@company.com
- **AWS Support**: (Production support case)
- **On-call Engineer**: (PagerDuty/incident management system)

## Security and Compliance

### Production Security Requirements
1. **Network Security**: Restricted CIDR access, private subnets
2. **Encryption**: EKS envelope encryption, EBS volume encryption
3. **IAM**: Principle of least privilege, IRSA implementation
4. **Monitoring**: Comprehensive logging and alerting
5. **Compliance**: Regular security scans and audits

### Audit and Compliance
```bash
# Enable audit logging (if not already configured)
aws eks update-cluster-config --name eks-deployment-prod --logging '{"enable":["api","audit","authenticator","controllerManager","scheduler"]}' --region us-east-1

# Review audit logs
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/eks-deployment-prod" --region us-east-1
```

### Regular Maintenance
- **Weekly**: Review monitoring dashboards and alerts
- **Monthly**: Update EKS addons and node AMIs
- **Quarterly**: Kubernetes version upgrades
- **Annually**: Security audit and compliance review

---

**Environment**: Production | **Last Updated**: 2025-01-03 | **Version**: 1.0 | **Classification**: Confidential
