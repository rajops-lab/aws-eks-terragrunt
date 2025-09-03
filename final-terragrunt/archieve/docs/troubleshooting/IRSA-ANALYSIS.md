# 🔐 IRSA Issue Analysis & Resolution Path

## 📊 **Current Situation**

### ❌ **Problem Identified**
- **Main Prometheus pod:** Stuck pending due to EBS CSI driver permission issues
- **Error:** `no EC2 IMDS role found, operation error ec2imds: GetMetadata, context deadline exceeded`
- **Root Cause:** EBS CSI service account lacks IRSA (IAM Roles for Service Accounts) configuration

### 🔍 **Current Configuration Status**

#### **✅ What's Working**
- **EBS CSI Addon:** Deployed and running (`aws-ebs-csi-driver`)
- **Service Account:** `ebs-csi-controller-sa` exists in `kube-system`
- **IRSA Code:** Terraform modules exist with EBS CSI IRSA configuration
- **OIDC Provider:** Likely exists (cluster has identity provider integration)

#### **❌ What's Missing**
- **Service Account Annotation:** No `eks.amazonaws.com/role-arn` annotation on `ebs-csi-controller-sa`
- **IAM Role:** No `eks-deployment-sandbox-ebs-csi-role` exists
- **IRSA Deployment:** IRSA resources not applied via Terragrunt

---

## 🎯 **Can Harry Fix This Independently?**

### ✅ **YES - Harry Can Fix It!**

**Your IAM permissions include:**
- `EKS_Full_Access_Without_Delete_Policy` - Can manage EKS resources
- `IAM_Rescrticted_Access_EKS_Policy` - Can create IAM roles for EKS
- `AmazonEC2FullAccess` - Can manage EC2/EBS resources
- Terragrunt execution permissions

### ⚠️ **Limitations Found**
- Cannot list/view existing OIDC providers (`iam:ListOpenIDConnectProviders` denied)
- Cannot view policy contents (`iam:GetPolicyVersion` denied)
- **But this won't prevent the fix!**

---

## 🛠️ **Resolution Path Options**

### **Option 1: Terragrunt Fix (Recommended) - 5 minutes**
The IRSA resources exist in your Terraform modules but aren't being deployed.

**Why it's not working:**
- `create_irsa_roles = true` in your config
- But `oidc_provider_arn` might be null or missing
- OIDC provider ARN is required for IRSA role creation

**Solution:**
```bash
# 1. Extract OIDC provider ARN from cluster
OIDC_ARN=$(aws eks describe-cluster --name eks-deployment-sandbox --region us-east-1 --query 'cluster.identity.oidc.issuer' --output text)

# 2. Update Terragrunt config with OIDC provider ARN
# 3. Run terragrunt apply to create IRSA roles
# 4. Patch service account with role annotation
```

### **Option 2: Manual IRSA Setup (Backup) - 10 minutes**
Create the IAM role manually and annotate the service account.

### **Option 3: Simplified Storage (Quick Fix) - 2 minutes**
Remove the pending Prometheus pod and use the working simple Prometheus.

---

## 📋 **Step-by-Step Fix Plan**

### **Phase 1: Diagnose OIDC Provider**
```bash
aws eks describe-cluster --name eks-deployment-sandbox --region us-east-1 --query 'cluster.identity.oidc.issuer'
```

### **Phase 2A: If OIDC Provider Exists (Most Likely)**
1. Update Terragrunt configuration with OIDC provider ARN
2. Run `terragrunt apply` to create IRSA roles
3. EKS addon will automatically use the new role

### **Phase 2B: If OIDC Provider Missing (Unlikely)**
1. Create OIDC provider via Terraform
2. Apply IRSA roles
3. Update service account

---

## ⏱️ **Time Estimates**

| Option | Time | Complexity | Permanence |
|--------|------|------------|------------|
| **Terragrunt Fix** | 5 min | Low | Permanent ✅ |
| **Manual IRSA** | 10 min | Medium | Permanent ✅ |
| **Simple Storage** | 2 min | Very Low | Temporary ⚠️ |

---

## 🎯 **Recommendation**

**Start with Option 1 (Terragrunt Fix)** because:
- ✅ Uses existing infrastructure-as-code approach
- ✅ Permanent solution integrated with your deployment
- ✅ You have sufficient permissions
- ✅ Preserves Terraform state consistency
- ✅ Most aligned with your current setup

### **Next Steps**
1. ✅ **You can proceed independently** - no admin support needed
2. 🔧 **I can guide you through the fix** step by step
3. 🚀 **ETA: 5-10 minutes** to full resolution

Would you like me to help you implement the Terragrunt fix right now?
