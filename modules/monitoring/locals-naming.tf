# =============================================================================
# CENTRALIZED NAMING FOR MONITORING MODULE
# =============================================================================
# This file implements centralized naming conventions for the monitoring module
# It references the root-level naming conventions and provides local mappings

locals {
  # =============================================================================
  # NAMING CONVENTIONS - Reference from root naming-conventions.tf
  # =============================================================================
  
  # Import base naming configuration
  naming_base = {
    cluster_name = var.cluster_name
    environment  = var.environment
    region_short = "use1"  # This should ideally be passed as a variable
  }

  # =============================================================================
  # KUBERNETES NAMESPACE NAMES - Centralized namespace naming
  # =============================================================================
  
  # Kubernetes namespaces with standardized naming
  namespace_names = {
    # Monitoring namespace
    # Old: var.monitoring_namespace (default: "monitoring")
    monitoring = "monitoring"
    
    # Kong namespace  
    # Old: var.kong_namespace (default: "kong")
    kong = "kong"
    
    # Additional monitoring namespaces
    observability = "observability"      # Alternative to monitoring
    logging       = "logging"            # For log-focused tools
    tracing       = "tracing"            # For tracing-focused tools
    metrics       = "metrics"            # For metrics-focused tools
    
    # System namespaces (for reference)
    kube_system     = "kube-system"
    ingress_nginx   = "ingress-nginx"
    cert_manager    = "cert-manager"
    external_dns    = "external-dns"
  }

  # =============================================================================
  # HELM RELEASE NAMES - Centralized Helm release naming
  # =============================================================================
  
  # Helm release names with standardized patterns
  helm_release_names = {
    # Prometheus stack
    # Old: var.prometheus_release_name (default: "prometheus-stack")
    prometheus_stack = "prometheus-stack"
    
    # Alternative prometheus naming patterns
    prometheus_operator = "prometheus-operator"
    kube_prometheus    = "kube-prometheus-stack"
    
    # Kong releases
    # Old: var.kong_release_name (default: "kong")
    kong = "kong"
    kong_ingress_controller = "kong-ingress-controller"
    
    # Jaeger releases  
    # Old: var.jaeger_release_name (default: "jaeger")
    jaeger = "jaeger"
    jaeger_operator = "jaeger-operator"
    
    # Loki releases
    # Old: var.loki_release_name (default: "loki")
    loki = "loki"
    loki_stack = "loki-stack"
    
    # Additional monitoring tools
    grafana     = "grafana"              # Standalone Grafana (if not using prometheus-stack)
    alertmanager = "alertmanager"        # Standalone Alertmanager
    pushgateway = "prometheus-pushgateway"
    blackbox    = "prometheus-blackbox-exporter"
    
    # Observability tools
    tempo       = "tempo"                # Grafana Tempo for tracing
    mimir       = "mimir"                # Grafana Mimir for metrics
    pyroscope   = "pyroscope"            # Grafana Pyroscope for profiling
    
    # Service mesh observability
    istio_base  = "istio-base"
    istio_istiod = "istiod"
    istio_gateway = "istio-gateway"
    
    # Security and policy
    falco       = "falco"                # Runtime security
    opa_gatekeeper = "gatekeeper"        # Policy enforcement
    
    # Log processing
    fluentd     = "fluentd"
    fluent_bit  = "fluent-bit"
    logstash    = "logstash"
    
    # APM and synthetic monitoring
    elastic_apm = "elastic-apm"
    uptime_kuma = "uptime-kuma"
    
    # Cost monitoring
    kubecost    = "kubecost"
    opencost    = "opencost"
  }

  # =============================================================================
  # KUBERNETES RESOURCE NAMES - Centralized K8s resource naming
  # =============================================================================
  
  # Kubernetes resource names (ConfigMaps, Secrets, ServiceMonitors, etc.)
  k8s_resource_names = {
    # Storage classes
    storage_class_monitoring = "monitoring-ssd"
    storage_class_logs      = "logs-ssd"
    storage_class_metrics   = "metrics-ssd"
    
    # ConfigMaps
    prometheus_config       = "prometheus-config"
    grafana_dashboards     = "grafana-dashboards"
    alertmanager_config    = "alertmanager-config"
    
    # Secrets
    grafana_admin_secret   = "grafana-admin-credentials"
    prometheus_auth_secret = "prometheus-auth"
    kong_admin_secret      = "kong-admin-credentials"
    
    # ServiceMonitors (Prometheus CRDs)
    app_service_monitor    = "app-metrics"
    kong_service_monitor   = "kong-metrics" 
    custom_service_monitor = "custom-app-metrics"
    
    # PrometheusRules (Prometheus CRDs)
    app_alerts_rule        = "app-alerts"
    infrastructure_rule    = "infrastructure-alerts"
    custom_rules           = "custom-prometheus-rules"
    
    # Ingress resources
    grafana_ingress        = "grafana-ingress"
    kong_manager_ingress   = "kong-manager-ingress"
    prometheus_ingress     = "prometheus-ingress"
  }

  # =============================================================================
  # TAGGING STRATEGY - Centralized tags for monitoring resources
  # =============================================================================
  
  # Standard tags for all monitoring resources
  standard_tags = merge(var.tags, {
    # Core identification tags
    Environment   = var.environment
    ClusterName   = var.cluster_name
    ManagedBy    = "Terraform"
    
    # Monitoring-specific tags
    Component    = "monitoring"
    Module       = "monitoring"
    Purpose      = "observability"
    
    # Stack information
    Stack        = "prometheus-grafana"
    Tier         = "monitoring"
  })

  # Component-specific tag sets
  tag_sets = {
    # Prometheus/metrics tags
    prometheus = merge(local.standard_tags, {
      Tool          = "prometheus"
      DataType      = "metrics"
      Retention     = var.prometheus_retention_days
    })
    
    # Grafana/visualization tags
    grafana = merge(local.standard_tags, {
      Tool          = "grafana"
      DataType      = "visualization"
      AccessType    = var.grafana_ingress_enabled ? "external" : "internal"
    })
    
    # Kong/API gateway tags
    kong = merge(local.standard_tags, {
      Tool          = "kong"
      DataType      = "api-gateway"
      ServiceType   = var.kong_proxy_service_type
    })
    
    # Jaeger/tracing tags
    jaeger = merge(local.standard_tags, {
      Tool          = "jaeger"
      DataType      = "traces"
      StorageType   = var.jaeger_storage_type
    })
    
    # Loki/logging tags
    loki = merge(local.standard_tags, {
      Tool          = "loki"
      DataType      = "logs"
      StorageSize   = var.loki_storage_size
    })
    
    # Kubernetes resources tags
    kubernetes = merge(local.standard_tags, {
      ResourceType  = "kubernetes-native"
      APIVersion    = "v1"
    })
    
    # Storage tags
    storage = merge(local.standard_tags, {
      ResourceType  = "storage"
      StorageClass  = "ssd"
      Encrypted     = "true"
    })
  }

  # =============================================================================
  # KUBERNETES LABELS - Centralized labels for K8s resources
  # =============================================================================
  
  # Standard Kubernetes labels for all monitoring resources
  kubernetes_labels = {
    # Standard labels (following K8s conventions)
    "app.kubernetes.io/part-of"     = "monitoring-stack"
    "app.kubernetes.io/managed-by"  = "terraform"
    "app.kubernetes.io/created-by"  = "terraform-monitoring-module"
    
    # Environment and cluster identification
    environment  = var.environment
    cluster-name = var.cluster_name
    
    # Monitoring-specific labels
    monitoring-stack = "prometheus-grafana"
    observability   = "enabled"
  }

  # Component-specific label sets
  kubernetes_label_sets = {
    # Namespace labels
    namespace = merge(local.kubernetes_labels, {
      "app.kubernetes.io/component" = "namespace"
      managed-by = "terraform"
    })
    
    # Helm release labels
    helm_release = merge(local.kubernetes_labels, {
      "app.kubernetes.io/component" = "helm-release"
      deployment-method = "helm"
    })
    
    # Prometheus labels
    prometheus = merge(local.kubernetes_labels, {
      "app.kubernetes.io/name"      = "prometheus"
      "app.kubernetes.io/component" = "metrics"
    })
    
    # Grafana labels
    grafana = merge(local.kubernetes_labels, {
      "app.kubernetes.io/name"      = "grafana"  
      "app.kubernetes.io/component" = "visualization"
    })
    
    # Kong labels
    kong = merge(local.kubernetes_labels, {
      "app.kubernetes.io/name"      = "kong"
      "app.kubernetes.io/component" = "api-gateway"
    })
  }

  # =============================================================================
  # CHART AND VERSION MANAGEMENT
  # =============================================================================
  
  # Chart repository URLs and versions (for consistency)
  chart_config = {
    # Prometheus community charts
    prometheus_repo = "https://prometheus-community.github.io/helm-charts"
    prometheus_chart = "kube-prometheus-stack"
    
    # Kong charts
    kong_repo = "https://charts.konghq.com"
    kong_chart = "kong"
    
    # Jaeger charts
    jaeger_repo = "https://jaegertracing.github.io/helm-charts"
    jaeger_chart = "jaeger"
    
    # Grafana/Loki charts
    grafana_repo = "https://grafana.github.io/helm-charts"
    loki_chart = "loki-stack"
    
    # Additional chart repositories
    bitnami_repo = "https://charts.bitnami.com/bitnami"
    elastic_repo = "https://helm.elastic.co"
    istio_repo   = "https://istio-release.storage.googleapis.com/charts"
  }

  # =============================================================================
  # VALIDATION - Ensure names meet Kubernetes requirements
  # =============================================================================
  
  # Validate resource name lengths and formats (K8s limits)
  validation = {
    # Namespace name validation (max 63 characters)
    monitoring_ns_valid = length(local.namespace_names.monitoring) <= 63
    kong_ns_valid = length(local.namespace_names.kong) <= 63
    
    # Helm release name validation (max 53 characters)
    prometheus_release_valid = length(local.helm_release_names.prometheus_stack) <= 53
    kong_release_valid = length(local.helm_release_names.kong) <= 53
    jaeger_release_valid = length(local.helm_release_names.jaeger) <= 53
    loki_release_valid = length(local.helm_release_names.loki) <= 53
    
    # Storage class name validation
    storage_class_valid = length(local.k8s_resource_names.storage_class_monitoring) <= 63
    
    # Kubernetes DNS subdomain validation (lowercase, alphanumeric, hyphens)
    namespace_format_valid = can(regex("^[a-z0-9-]+$", local.namespace_names.monitoring))
    release_format_valid = can(regex("^[a-z0-9-]+$", local.helm_release_names.prometheus_stack))
  }
}

# =============================================================================
# OUTPUTS FOR MODULE INTERNAL USE
# =============================================================================

# These outputs make the centralized names available to other resources in the module
# They should be used instead of hardcoded names or variables

# Namespace names
output "internal_namespace_names" {
  description = "Centralized namespace names for internal module use"
  value = local.namespace_names
}

# Helm release names
output "internal_helm_release_names" {
  description = "Centralized Helm release names for internal module use"
  value = local.helm_release_names
}

# Kubernetes resource names
output "internal_k8s_resource_names" {
  description = "Centralized Kubernetes resource names for internal module use" 
  value = local.k8s_resource_names
}

# Tag sets
output "internal_tag_sets" {
  description = "Centralized tag sets for internal module use"
  value = local.tag_sets
}

# Kubernetes label sets
output "internal_kubernetes_label_sets" {
  description = "Centralized Kubernetes label sets for internal module use"
  value = local.kubernetes_label_sets
}

# Chart configuration
output "internal_chart_config" {
  description = "Chart repository and configuration for internal module use"
  value = local.chart_config
}
