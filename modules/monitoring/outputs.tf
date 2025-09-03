# Outputs for Monitoring Module

# ========================================
# General Information
# ========================================
output "monitoring_namespace" {
  description = "Kubernetes namespace where monitoring tools are deployed"
  value       = var.monitoring_namespace
}

output "kong_namespace" {
  description = "Kubernetes namespace where Kong is deployed"
  value       = var.kong_namespace
}

# ========================================
# Prometheus Stack Outputs
# ========================================
output "prometheus_stack_deployed" {
  description = "Whether Prometheus stack is deployed"
  value       = var.enable_prometheus
}

output "prometheus_release_name" {
  description = "Helm release name of Prometheus stack"
  value       = var.enable_prometheus ? var.prometheus_release_name : null
}

output "prometheus_chart_version" {
  description = "Version of Prometheus chart deployed"
  value       = var.enable_prometheus ? var.prometheus_chart_version : null
}

output "grafana_admin_service" {
  description = "Grafana admin service access information"
  value = var.enable_prometheus ? {
    namespace = var.monitoring_namespace
    service   = "${var.prometheus_release_name}-grafana"
    port      = 80
    username  = "admin"
  } : null
}

output "prometheus_server_service" {
  description = "Prometheus server service access information"
  value = var.enable_prometheus ? {
    namespace = var.monitoring_namespace
    service   = "${var.prometheus_release_name}-prometheus-server"
    port      = 9090
  } : null
}

output "alertmanager_service" {
  description = "Alertmanager service access information"
  value = var.enable_prometheus ? {
    namespace = var.monitoring_namespace
    service   = "${var.prometheus_release_name}-alertmanager"
    port      = 9093
  } : null
}

# ========================================
# Kong Outputs
# ========================================
output "kong_deployed" {
  description = "Whether Kong is deployed"
  value       = var.enable_kong
}

output "kong_release_name" {
  description = "Helm release name of Kong"
  value       = var.enable_kong ? var.kong_release_name : null
}

output "kong_chart_version" {
  description = "Version of Kong chart deployed"
  value       = var.enable_kong ? var.kong_chart_version : null
}

output "kong_proxy_service" {
  description = "Kong proxy service access information"
  value = var.enable_kong ? {
    namespace = var.kong_namespace
    service   = "${var.kong_release_name}-kong-proxy"
    http_port = 80
    https_port = 443
    type      = var.kong_proxy_service_type
  } : null
}

output "kong_admin_service" {
  description = "Kong admin service access information"
  value = var.enable_kong && var.kong_admin_enabled ? {
    namespace = var.kong_namespace
    service   = "${var.kong_release_name}-kong-admin"
    port      = 8001
    type      = var.kong_admin_service_type
  } : null
}

output "kong_manager_service" {
  description = "Kong manager service access information"
  value = var.enable_kong && var.kong_manager_enabled ? {
    namespace = var.kong_namespace
    service   = "${var.kong_release_name}-kong-manager"
    port      = 8002
  } : null
}

# ========================================
# Jaeger Outputs
# ========================================
output "jaeger_deployed" {
  description = "Whether Jaeger is deployed"
  value       = var.enable_jaeger
}

output "jaeger_release_name" {
  description = "Helm release name of Jaeger"
  value       = var.enable_jaeger ? var.jaeger_release_name : null
}

output "jaeger_ui_service" {
  description = "Jaeger UI service access information"
  value = var.enable_jaeger ? {
    namespace = var.monitoring_namespace
    service   = "${var.jaeger_release_name}-jaeger-query"
    port      = 16686
  } : null
}

# ========================================
# Loki Outputs
# ========================================
output "loki_deployed" {
  description = "Whether Loki is deployed"
  value       = var.enable_loki
}

output "loki_release_name" {
  description = "Helm release name of Loki"
  value       = var.enable_loki ? var.loki_release_name : null
}

output "loki_service" {
  description = "Loki service access information"
  value = var.enable_loki ? {
    namespace = var.monitoring_namespace
    service   = var.loki_release_name
    port      = 3100
  } : null
}

# ========================================
# Access Commands
# ========================================
output "access_commands" {
  description = "Commands to access monitoring services"
  value = {
    grafana = var.enable_prometheus ? {
      port_forward = "kubectl port-forward -n ${var.monitoring_namespace} svc/${var.prometheus_release_name}-grafana 3000:80"
      username     = "admin"
      get_password = "kubectl get secret -n ${var.monitoring_namespace} ${var.prometheus_release_name}-grafana -o jsonpath='{.data.admin-password}' | base64 --decode"
    } : null
    
    prometheus = var.enable_prometheus ? {
      port_forward = "kubectl port-forward -n ${var.monitoring_namespace} svc/${var.prometheus_release_name}-prometheus-server 9090:80"
    } : null
    
    alertmanager = var.enable_prometheus ? {
      port_forward = "kubectl port-forward -n ${var.monitoring_namespace} svc/${var.prometheus_release_name}-alertmanager 9093:9093"
    } : null
    
    kong_proxy = var.enable_kong ? {
      port_forward = "kubectl port-forward -n ${var.kong_namespace} svc/${var.kong_release_name}-kong-proxy 8000:80"
    } : null
    
    kong_admin = var.enable_kong && var.kong_admin_enabled ? {
      port_forward = "kubectl port-forward -n ${var.kong_namespace} svc/${var.kong_release_name}-kong-admin 8001:8001"
    } : null
    
    kong_manager = var.enable_kong && var.kong_manager_enabled ? {
      port_forward = "kubectl port-forward -n ${var.kong_namespace} svc/${var.kong_release_name}-kong-manager 8002:8002"
    } : null
    
    jaeger = var.enable_jaeger ? {
      port_forward = "kubectl port-forward -n ${var.monitoring_namespace} svc/${var.jaeger_release_name}-jaeger-query 16686:16686"
    } : null
  }
}

# ========================================
# Deployment Summary
# ========================================
output "deployment_summary" {
  description = "Summary of deployed monitoring components"
  value = {
    prometheus_stack = var.enable_prometheus ? "✅ Deployed" : "❌ Disabled"
    grafana         = var.enable_prometheus ? "✅ Deployed" : "❌ Disabled"
    kong_gateway    = var.enable_kong ? "✅ Deployed" : "❌ Disabled"
    kong_ingress_controller = var.enable_kong && var.enable_kong_ingress_controller ? "✅ Deployed" : "❌ Disabled"
    jaeger_tracing  = var.enable_jaeger ? "✅ Deployed" : "❌ Disabled"
    loki_logging    = var.enable_loki ? "✅ Deployed" : "❌ Disabled"
    
    namespaces = {
      monitoring = var.monitoring_namespace
      kong       = var.kong_namespace
    }
    
    total_components = (var.enable_prometheus ? 1 : 0) + (var.enable_kong ? 1 : 0) + (var.enable_jaeger ? 1 : 0) + (var.enable_loki ? 1 : 0)
  }
}

# ========================================
# URLs (when ingress is enabled)
# ========================================
output "ingress_urls" {
  description = "URLs for accessing services via ingress"
  value = {
    grafana = var.enable_prometheus && var.grafana_ingress_enabled ? "http://${var.grafana_ingress_host}" : "Ingress not enabled"
    kong_manager = var.enable_kong && var.kong_ingress_enabled ? "http://${var.kong_ingress_host}" : "Ingress not enabled"
  }
}
