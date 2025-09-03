# Monitoring Module - Deploys Prometheus, Grafana, and Kong
# This module creates a complete monitoring stack for EKS

# PROVIDER VERSIONS NOW MANAGED CENTRALLY BY TERRAGRUNT ROOT CONFIG
# terraform {
#   required_providers {
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.38"  # Latest stable 2.38.x
#     }
#     helm = {
#       source  = "hashicorp/helm"
#       version = "~> 2.17"  # Latest stable 2.17.x
#     }
#   }
# }

# =============================================================================
# HELM REPOSITORY INITIALIZATION
# =============================================================================
# Initialize Helm repositories using null_resource with local-exec
# This is required because Terraform Helm provider doesn't manage repositories directly

resource "null_resource" "init_helm_repos" {
  count = var.enabled && var.enable_prometheus ? 1 : 0
  
  provisioner "local-exec" {
    command = <<-EOT
      helm repo add prometheus-community ${local.chart_config.prometheus_repo} || true
      helm repo add kong ${local.chart_config.kong_repo} || true
      helm repo add grafana ${local.chart_config.grafana_repo} || true
      helm repo update
    EOT
  }
  
  # Trigger re-run if repository URLs change
  triggers = {
    prometheus_repo = local.chart_config.prometheus_repo
    kong_repo      = local.chart_config.kong_repo
    grafana_repo   = local.chart_config.grafana_repo
  }
}

# =============================================================================
# KUBERNETES NAMESPACES
# =============================================================================

# CENTRALIZED NAMING: Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = var.enabled && var.create_namespace ? 1 : 0
  
  metadata {
    # Old: name = var.monitoring_namespace
    name = local.namespace_names.monitoring
    
    # CENTRALIZED LABELS: Use namespace label set
    # Old: labels = { name = var.monitoring_namespace, managed-by = "terraform", environment = var.environment }
    labels = merge(local.kubernetes_label_sets.namespace, {
      name = local.namespace_names.monitoring
    })
  }
}

# CENTRALIZED NAMING: Create Kong namespace (if Kong is enabled)
resource "kubernetes_namespace" "kong" {
  count = var.enabled && var.enable_kong && var.create_namespace ? 1 : 0
  
  metadata {
    # Old: name = var.kong_namespace
    name = local.namespace_names.kong
    
    # CENTRALIZED LABELS: Use namespace label set
    # Old: labels = { name = var.kong_namespace, managed-by = "terraform", environment = var.environment }
    labels = merge(local.kubernetes_label_sets.namespace, {
      name = local.namespace_names.kong
    })
  }
}

# CENTRALIZED NAMING: Prometheus Operator (kube-prometheus-stack)
resource "helm_release" "prometheus_stack" {
  count = var.enabled && var.enable_prometheus ? 1 : 0

  # Old: name = var.prometheus_release_name
  name       = local.helm_release_names.prometheus_stack
  # FIXED: Use repository URL directly (Terraform Helm provider doesn't support helm_repository resources)
  # Old: repository = "https://prometheus-community.github.io/helm-charts"
  repository = local.chart_config.prometheus_repo
  # Old: chart = "kube-prometheus-stack"
  chart      = local.chart_config.prometheus_chart
  version    = var.prometheus_chart_version
  # Old: namespace = var.monitoring_namespace
  namespace  = local.namespace_names.monitoring

  # Wait for CRDs to be established
  wait             = true
  timeout          = 600
  create_namespace = false

  values = [
    templatefile("${path.module}/templates/prometheus-values.yaml", {
      grafana_admin_password     = var.grafana_admin_password
      grafana_storage_size      = var.grafana_storage_size
      prometheus_storage_size   = var.prometheus_storage_size
      alertmanager_storage_size = var.alertmanager_storage_size
      grafana_ingress_enabled   = var.grafana_ingress_enabled
      grafana_ingress_host      = var.grafana_ingress_host
      prometheus_retention      = var.prometheus_retention_days
      environment              = var.environment
      cluster_name             = var.cluster_name
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring,
    null_resource.init_helm_repos
  ]
}

# CENTRALIZED NAMING: Kong API Gateway
resource "helm_release" "kong" {
  count = var.enabled && var.enable_kong ? 1 : 0

  # Old: name = var.kong_release_name
  name       = local.helm_release_names.kong
  # Old: repository = "https://charts.konghq.com"
  repository = local.chart_config.kong_repo
  # Old: chart = "kong"
  chart      = local.chart_config.kong_chart
  version    = var.kong_chart_version
  # Old: namespace = var.kong_namespace
  namespace  = local.namespace_names.kong

  wait             = true
  timeout          = 300
  create_namespace = false

  values = [
    templatefile("${path.module}/templates/kong-values.yaml", {
      kong_admin_enabled    = var.kong_admin_enabled
      kong_manager_enabled  = var.kong_manager_enabled
      kong_proxy_type      = var.kong_proxy_service_type
      kong_admin_type      = var.kong_admin_service_type
      kong_ingress_enabled = var.kong_ingress_enabled
      kong_ingress_host    = var.kong_ingress_host
      environment          = var.environment
      cluster_name         = var.cluster_name
    })
  ]

  depends_on = [
    kubernetes_namespace.kong
  ]
}

# CENTRALIZED NAMING: Kong Ingress Controller (if enabled)
resource "helm_release" "kong_ingress_controller" {
  count = var.enabled && var.enable_kong && var.enable_kong_ingress_controller ? 1 : 0

  # Old: name = "kong-ingress-controller"
  name       = local.helm_release_names.kong_ingress_controller
  # Old: repository = "https://charts.konghq.com"
  repository = local.chart_config.kong_repo
  # Old: chart = "kong"
  chart      = local.chart_config.kong_chart
  version    = var.kong_chart_version
  # Old: namespace = var.kong_namespace
  namespace  = local.namespace_names.kong

  wait             = true
  timeout          = 300
  create_namespace = false

  values = [
    templatefile("${path.module}/templates/kong-ingress-controller-values.yaml", {
      environment  = var.environment
      cluster_name = var.cluster_name
    })
  ]

  depends_on = [
    helm_release.kong
  ]
}

# CENTRALIZED NAMING: Jaeger Tracing (Optional)
resource "helm_release" "jaeger" {
  count = var.enabled && var.enable_jaeger ? 1 : 0

  # Old: name = var.jaeger_release_name
  name       = local.helm_release_names.jaeger
  # Old: repository = "https://jaegertracing.github.io/helm-charts"
  repository = local.chart_config.jaeger_repo
  # Old: chart = "jaeger"
  chart      = local.chart_config.jaeger_chart
  version    = var.jaeger_chart_version
  # Old: namespace = var.monitoring_namespace
  namespace  = local.namespace_names.monitoring

  wait             = true
  timeout          = 300
  create_namespace = false

  values = [
    templatefile("${path.module}/templates/jaeger-values.yaml", {
      jaeger_storage_type = var.jaeger_storage_type
      environment         = var.environment
      cluster_name        = var.cluster_name
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# CENTRALIZED NAMING: Additional monitoring tools
# Loki for log aggregation (Optional)
resource "helm_release" "loki" {
  count = var.enabled && var.enable_loki ? 1 : 0

  # Old: name = var.loki_release_name
  name       = local.helm_release_names.loki
  # Old: repository = "https://grafana.github.io/helm-charts"
  repository = local.chart_config.grafana_repo
  # Old: chart = "loki-stack"
  chart      = local.chart_config.loki_chart
  version    = var.loki_chart_version
  # Old: namespace = var.monitoring_namespace
  namespace  = local.namespace_names.monitoring

  wait             = true
  timeout          = 300
  create_namespace = false

  values = [
    templatefile("${path.module}/templates/loki-values.yaml", {
      loki_storage_size = var.loki_storage_size
      environment       = var.environment
      cluster_name      = var.cluster_name
    })
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# CENTRALIZED NAMING: Service monitors for custom applications
resource "kubernetes_manifest" "custom_service_monitors" {
  for_each = var.enable_prometheus ? var.custom_service_monitors : {}

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = each.key
      # Old: namespace = var.monitoring_namespace
      namespace = local.namespace_names.monitoring
      # CENTRALIZED LABELS: Use Prometheus label set
      # Old: labels = { managed-by = "terraform" }
      labels = merge(local.kubernetes_label_sets.prometheus, {
        managed-by = "terraform"
      })
    }
    spec = each.value
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

# CENTRALIZED NAMING: Prometheus Rules for custom alerts
resource "kubernetes_manifest" "custom_prometheus_rules" {
  for_each = var.enable_prometheus ? var.custom_prometheus_rules : {}

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = each.key
      # Old: namespace = var.monitoring_namespace
      namespace = local.namespace_names.monitoring
      # CENTRALIZED LABELS: Use Prometheus label set
      # Old: labels = { managed-by = "terraform", prometheus = "kube-prometheus" }
      labels = merge(local.kubernetes_label_sets.prometheus, {
        managed-by = "terraform"
        prometheus = "kube-prometheus"
      })
    }
    spec = each.value
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}

# CENTRALIZED NAMING: Create storage classes if needed
resource "kubernetes_storage_class" "monitoring_ssd" {
  count = var.create_storage_class ? 1 : 0

  metadata {
    # Old: name = "monitoring-ssd"
    name = local.k8s_resource_names.storage_class_monitoring
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type      = "gp3"
    encrypted = "true"
  }
}
