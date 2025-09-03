#!/bin/bash

# EKS Node Group User Data Script
# This script bootstraps EC2 instances to join the EKS cluster

set -o xtrace

# Pre-bootstrap user data
${pre_bootstrap_user_data}

# Bootstrap the node
/etc/eks/bootstrap.sh '${cluster_name}' \
  --b64-cluster-ca '${cluster_auth_base64}' \
  --apiserver-endpoint '${cluster_endpoint}' \
  ${bootstrap_extra_args}

# Post-bootstrap user data
${post_bootstrap_user_data}
