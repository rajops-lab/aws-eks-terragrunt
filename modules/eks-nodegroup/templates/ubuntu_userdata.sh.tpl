#!/bin/bash

# EKS Node Group User Data Script for Ubuntu
# This script bootstraps Ubuntu EC2 instances to join the EKS cluster

set -o xtrace

# Update system packages
apt-get update -y

# Pre-bootstrap user data
${pre_bootstrap_user_data}

# Install required packages
apt-get install -y curl wget unzip

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws/
fi

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Install kubectl
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install Docker (required for EKS)
apt-get install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Install kubelet and other Kubernetes components
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm

# Configure kubelet for EKS
mkdir -p /etc/kubernetes/kubelet
mkdir -p /etc/systemd/system/kubelet.service.d

# Create kubelet configuration
cat > /etc/kubernetes/kubelet/kubelet-config.json <<EOF
{
    "kind": "KubeletConfiguration",
    "apiVersion": "kubelet.config.k8s.io/v1beta1",
    "address": "0.0.0.0",
    "authentication": {
        "anonymous": {
            "enabled": false
        },
        "webhook": {
            "cacheTTL": "2m0s",
            "enabled": true
        },
        "x509": {
            "clientCAFile": "/etc/kubernetes/pki/ca.crt"
        }
    },
    "authorization": {
        "mode": "Webhook",
        "webhook": {
            "cacheAuthorizedTTL": "5m0s",
            "cacheUnauthorizedTTL": "30s"
        }
    },
    "clusterDomain": "cluster.local",
    "hairpinMode": "hairpin-veth",
    "readOnlyPort": 0,
    "cgroupDriver": "systemd",
    "cgroupRoot": "/",
    "featureGates": {
        "RotateKubeletServerCertificate": true
    },
    "protectKernelDefaults": true,
    "serializeImagePulls": false,
    "serverTLSBootstrap": true,
    "tlsCipherSuites": [
        "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
        "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
        "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
        "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
        "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
        "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384",
        "TLS_RSA_WITH_AES_256_GCM_SHA384",
        "TLS_RSA_WITH_AES_128_GCM_SHA256"
    ]
}
EOF

# Get cluster CA certificate
aws eks describe-cluster --region $REGION --name ${cluster_name} --query 'cluster.certificateAuthority.data' --output text | base64 -d > /etc/kubernetes/pki/ca.crt

# Create kubelet systemd service
cat > /etc/systemd/system/kubelet.service <<EOF
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/

[Service]
ExecStart=/usr/bin/kubelet \\
    --config=/etc/kubernetes/kubelet/kubelet-config.json \\
    --kubeconfig=/var/lib/kubelet/kubeconfig \\
    --container-runtime=docker \\
    --image-pull-progress-deadline=2m \\
    --kubeconfig=/var/lib/kubelet/kubeconfig \\
    --network-plugin=cni \\
    --node-ip=\$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4) \\
    --pod-infra-container-image=602401143452.dkr.ecr.$REGION.amazonaws.com/eks/pause:3.1-eksbuild.1 \\
    --v=2 \\
    --cloud-provider=aws \\
    --container-runtime-endpoint=unix:///var/run/dockershim.sock \\
    ${bootstrap_extra_args}

Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create kubeconfig for kubelet
mkdir -p /var/lib/kubelet
cat > /var/lib/kubelet/kubeconfig <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/pki/ca.crt
    server: ${cluster_endpoint}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: kubelet
current-context: kubelet
users:
- name: kubelet
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws
      args:
      - eks
      - get-token
      - --cluster-name
      - ${cluster_name}
      - --region
      - $REGION
EOF

# Install CNI plugins
CNI_VERSION="v0.8.2"
mkdir -p /opt/cni/bin
curl -L "https://github.com/containernetworking/plugins/releases/download/$CNI_VERSION/cni-plugins-linux-amd64-$CNI_VERSION.tgz" | tar -C /opt/cni/bin -xz

# Install AWS VPC CNI plugin
curl -o aws-k8s-cni.yaml https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.6/aws-k8s-cni.yaml

# Enable and start kubelet
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet

# Install and configure AWS IAM Authenticator
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
chmod +x aws-iam-authenticator
mv aws-iam-authenticator /usr/local/bin/

# Configure node labels
kubectl --kubeconfig=/var/lib/kubelet/kubeconfig label node $INSTANCE_ID node.kubernetes.io/instance-type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type) --overwrite || true

# Post-bootstrap user data
${post_bootstrap_user_data}
