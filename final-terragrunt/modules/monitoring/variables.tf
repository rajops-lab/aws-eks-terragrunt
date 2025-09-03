# Variables for Monitoring Module

# ========================================
# General Configuration
# ========================================
variable "enabled" {
  description = "Whether to enable deployment of observability (Prometheus/Grafana) and/or Kong"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create monitoring and Kong namespaces"
  type        = bool
  default     = true
}

variable "create_storage_class" {
  description = "Whether to create a dedicated storage class for monitoring"
  type        = bool
  default     = true
}

# ========================================
# Namespace Configuration
# ========================================
variable "monitoring_namespace" {
  description = "Kubernetes namespace for monitoring tools"
  type        = string
  default     = "monitoring"
}

variable "kong_namespace" {
  description = "Kubernetes namespace for Kong API Gateway"
  type        = string
  default     = "kong"
}

# ========================================
# Prometheus Configuration
# ========================================
variable "enable_prometheus" {
  description = "Enable Prometheus monitoring stack"
  type        = bool
  default     = true
}

variable "prometheus_release_name" {
  description = "Helm release name for Prometheus stack"
  type        = string
  default     = "prometheus-stack"
}

variable "prometheus_chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "69.2.0"
}

variable "prometheus_retention_days" {
  description = "Data retention period for Prometheus in days"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus server"
  type        = string
  default     = "50Gi"
}

variable "alertmanager_storage_size" {
  description = "Storage size for Alertmanager"
  type        = string
  default     = "10Gi"
}

# ========================================
# Grafana Configuration
# ========================================
variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "grafana_ingress_enabled" {
  description = "Enable ingress for Grafana"
  type        = bool
  default     = true
}

variable "grafana_ingress_host" {
  description = "Hostname for Grafana ingress"
  type        = string
  default     = "grafana.local"
}

# ========================================
# Kong Configuration
# ========================================
variable "enable_kong" {
  description = "Enable Kong API Gateway"
  type        = bool
  default     = true
}

variable "kong_release_name" {
  description = "Helm release name for Kong"
  type        = string
  default     = "kong"
}

variable "kong_chart_version" {
  description = "Version of Kong Helm chart"
  type        = string
  default     = "2.42.0"
}

variable "kong_proxy_service_type" {
  description = "Service type for Kong proxy"
  type        = string
  default     = "LoadBalancer"
  validation {
    condition     = contains(["LoadBalancer", "ClusterIP", "NodePort"], var.kong_proxy_service_type)
    error_message = "Kong proxy service type must be LoadBalancer, ClusterIP, or NodePort."
  }
}

variable "kong_admin_service_type" {
  description = "Service type for Kong admin"
  type        = string
  default     = "ClusterIP"
  validation {
    condition     = contains(["LoadBalancer", "ClusterIP", "NodePort"], var.kong_admin_service_type)
    error_message = "Kong admin service type must be LoadBalancer, ClusterIP, or NodePort."
  }
}

variable "kong_admin_enabled" {
  description = "Enable Kong Admin API"
  type        = bool
  default     = true
}

variable "kong_manager_enabled" {
  description = "Enable Kong Manager UI"
  type        = bool
  default     = true
}

variable "kong_ingress_enabled" {
  description = "Enable ingress for Kong Manager"
  type        = bool
  default     = false
}

variable "kong_ingress_host" {
  description = "Hostname for Kong Manager ingress"
  type        = string
  default     = "kong-manager.local"
}

variable "enable_kong_ingress_controller" {
  description = "Enable Kong Ingress Controller"
  type        = bool
  default     = true
}

# ========================================
# Jaeger Configuration
# ========================================
variable "enable_jaeger" {
  description = "Enable Jaeger distributed tracing"
  type        = bool
  default     = false
}

variable "jaeger_release_name" {
  description = "Helm release name for Jaeger"
  type        = string
  default     = "jaeger"
}

variable "jaeger_chart_version" {
  description = "Version of Jaeger Helm chart"
  type        = string
  default     = "3.5.0"
}

variable "jaeger_storage_type" {
  description = "Storage type for Jaeger (memory, elasticsearch, cassandra)"
  type        = string
  default     = "memory"
  validation {
    condition     = contains(["memory", "elasticsearch", "cassandra"], var.jaeger_storage_type)
    error_message = "Jaeger storage type must be memory, elasticsearch, or cassandra."
  }
}

# ========================================
# Loki Configuration
# ========================================
variable "enable_loki" {
  description = "Enable Loki log aggregation"
  type        = bool
  default     = false
}

variable "loki_release_name" {
  description = "Helm release name for Loki"
  type        = string
  default     = "loki"
}

variable "loki_chart_version" {
  description = "Version of Loki Helm chart"
  type        = string
  default     = "6.34.0"
}

variable "loki_storage_size" {
  description = "Storage size for Loki"
  type        = string
  default     = "20Gi"
}

# ========================================
# Custom Monitoring Configuration
# ========================================
variable "custom_service_monitors" {
  description = "Custom ServiceMonitor configurations"
  type        = map(any)
  default     = {}
}

variable "custom_prometheus_rules" {
  description = "Custom PrometheusRule configurations"
  type        = map(any)
  default     = {}
}

# ========================================
# Tags
# ========================================
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
