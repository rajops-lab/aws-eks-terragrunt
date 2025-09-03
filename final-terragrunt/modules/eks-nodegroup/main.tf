################################################################################
# EKS Node Group - Simple and Clean Implementation
################################################################################

# Node Group IAM Role
resource "aws_iam_role" "node_group" {
  count = var.enabled ? 1 : 0
  name  = "${var.node_group_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach required policies to node group role
resource "aws_iam_role_policy_attachment" "worker_node_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "registry_readonly" {
  count      = var.enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[0].name
}

# Optional SSM access for node management
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  count      = var.enabled && var.enable_ssm_access ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group[0].name
}

# Launch Template (optional but recommended)
resource "aws_launch_template" "node_group" {
  count       = var.enabled && var.use_launch_template ? 1 : 0
  name        = "${var.node_group_name}-launch-template"
  description = "Launch template for ${var.node_group_name}"

  vpc_security_group_ids = var.security_group_ids

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type          = "gp3"
      encrypted            = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring {
    enabled = true
  }

  user_data = var.user_data_base64

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.node_group_name}-node"
    })
  }

  tags = var.tags
}

# EKS Node Group
resource "aws_eks_node_group" "node_group" {
  count           = var.enabled ? 1 : 0
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group[0].arn
  subnet_ids      = var.subnet_ids
  version         = var.kubernetes_version

  capacity_type  = var.capacity_type
  ami_type       = var.ami_type
  instance_types = var.instance_types
  disk_size      = var.use_launch_template ? null : var.disk_size

  # Scaling configuration
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # Update configuration
  update_config {
    max_unavailable = var.max_unavailable
  }

  # Launch template (if using)
  dynamic "launch_template" {
    for_each = var.use_launch_template ? [1] : []
    content {
      id      = aws_launch_template.node_group[0].id
      version = aws_launch_template.node_group[0].latest_version
    }
  }

  # Remote access (if SSH key provided)
  dynamic "remote_access" {
    for_each = var.ssh_key_name != null ? [1] : []
    content {
      ec2_ssh_key               = var.ssh_key_name
      source_security_group_ids = var.ssh_security_group_ids
    }
  }

  # Labels
  labels = var.labels

  # Taints (if any)
  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  depends_on = [
    aws_iam_role_policy_attachment.worker_node_policy,
    aws_iam_role_policy_attachment.cni_policy,
    aws_iam_role_policy_attachment.registry_readonly,
  ]

  tags = var.tags

  # Allow external changes to desired_size without forcing update
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
