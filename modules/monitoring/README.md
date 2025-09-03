# EKS Monitoring Module

A comprehensive Terraform module for deploying monitoring and observability tools on Amazon EKS, including Prometheus, Grafana, Kong API Gateway, Jaeger, and Loki.

## 🏗️ Architecture Overview

This module deploys a complete monitoring stack:

```
┌─────────────────────────────────────────────────────────────┐
│                     EKS Cluster                             │
│                                                             │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ │
│ │   Monitoring    │ │      Kong       │ │   Applications  │ │
│ │   Namespace     │ │   Namespace     │ │   Namespaces    │ │
│ │                 │ │                 │ │                 │ │
│ │ • Prometheus    │ │ • Kong Gateway  │ │ • Your Apps     │ │
│ │ • Grafana       │ │ • Kong Admin    │ │ • Service       │ │
│ │ • Alertmanager  │ │ • Kong Manager  │ │   Monitors      │ │
│ │ • Jaeger (opt)  │ │ • Ingress Ctrl  │ │ • Custom Rules  │ │
│ │ • Loki (opt)    │ │                 │ │                 │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Features

### Core Monitoring
- **Prometheus Stack**: Complete observability with kube-prometheus-stack
- **Grafana**: Pre-configured dashboards and data sources
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Host-level metrics
- **kube-state-metrics**: Kubernetes resource metrics

### API Gateway
- **Kong**: High-performance API gateway
- **Kong Manager**: Web-based administration interface
- **Kong Ingress Controller**: Kubernetes-native ingress
- **Service monitoring**: Built-in Prometheus metrics

### Optional Components
- **Jaeger**: Distributed tracing (memory/elasticsearch/cassandra)
- **Loki**: Log aggregation with Promtail
- **Custom ServiceMonitors**: Monitor your applications
- **Custom PrometheusRules**: Custom alerting rules

## 📋 Prerequisites

- EKS cluster (1.21+)
- Helm 3.x
- kubectl configured
- AWS Load Balancer Controller (for Kong LoadBalancer services)
- EBS CSI Driver (for persistent volumes)

## 🛠️ Usage

### Basic Setup

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  # Required variables
  cluster_name             = "my-eks-cluster"
  environment              = "production"
  grafana_admin_password   = "secure-password-here"
  
  # Enable/disable components
  enable_prometheus        = true
  enable_kong             = true
  enable_jaeger           = false
  enable_loki             = false
  
  # Grafana configuration
  grafana_ingress_enabled  = true
  grafana_ingress_host     = "grafana.example.com"
  
  # Kong configuration
  kong_proxy_service_type  = "LoadBalancer"
  kong_admin_enabled       = true
  kong_manager_enabled     = true
}
```

### Advanced Configuration

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name           = "my-eks-cluster"
  environment            = "production"
  grafana_admin_password = var.grafana_password
  
  # Storage configuration
  prometheus_storage_size   = "100Gi"
  grafana_storage_size     = "20Gi"
  alertmanager_storage_size = "15Gi"
  
  # Retention
  prometheus_retention_days = "30d"
  
  # Kong with custom service types
  enable_kong              = true
  kong_proxy_service_type  = "LoadBalancer"
  kong_admin_service_type  = "ClusterIP"
  kong_ingress_enabled     = true
  kong_ingress_host        = "kong.example.com"
  
  # Optional components
  enable_jaeger            = true
  jaeger_storage_type      = "elasticsearch"
  
  enable_loki             = true
  loki_storage_size       = "50Gi"
  
  # Custom monitoring
  custom_service_monitors = {
    my-app = {
      selector = {
        matchLabels = {
          app = "my-application"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
        }
      ]
    }
  }
  
  custom_prometheus_rules = {
    my-alerts = {
      groups = [
        {
          name = "my-application"
          rules = [
            {
              alert = "HighErrorRate"
              expr  = "rate(http_requests_total{status=~\"5..\"}[5m]) > 0.1"
              for   = "5m"
              labels = {
                severity = "warning"
              }
              annotations = {
                summary = "High error rate detected"
              }
            }
          ]
        }
      ]
    }
  }
}
```

## 📊 Accessing Services

After deployment, you can access the monitoring services:

### Port Forward Access

```bash
# Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-stack-prometheus-server 9090:80

# Alertmanager
kubectl port-forward -n monitoring svc/prometheus-stack-alertmanager 9093:9093

# Kong Proxy
kubectl port-forward -n kong svc/kong-kong-proxy 8000:80

# Kong Admin
kubectl port-forward -n kong svc/kong-kong-admin 8001:8001

# Kong Manager
kubectl port-forward -n kong svc/kong-kong-manager 8002:8002
```

### Ingress Access (if enabled)

- Grafana: `http://grafana.example.com`
- Kong Manager: `http://kong.example.com`

### Default Credentials

- **Grafana**: 
  - Username: `admin`
  - Password: Value of `grafana_admin_password` variable

## 🔧 Configuration

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `cluster_name` | string | - | **Required** EKS cluster name |
| `environment` | string | - | **Required** Environment name |
| `grafana_admin_password` | string | - | **Required** Grafana admin password |
| `enable_prometheus` | bool | `true` | Deploy Prometheus stack |
| `enable_kong` | bool | `true` | Deploy Kong API Gateway |
| `enable_jaeger` | bool | `false` | Deploy Jaeger tracing |
| `enable_loki` | bool | `false` | Deploy Loki logging |
| `monitoring_namespace` | string | `"monitoring"` | Kubernetes namespace for monitoring |
| `kong_namespace` | string | `"kong"` | Kubernetes namespace for Kong |
| `prometheus_storage_size` | string | `"50Gi"` | Prometheus storage size |
| `grafana_storage_size` | string | `"10Gi"` | Grafana storage size |
| `kong_proxy_service_type` | string | `"LoadBalancer"` | Kong proxy service type |

See `variables.tf` for complete list of configurable options.

### Outputs

| Output | Description |
|--------|-------------|
| `monitoring_namespace` | Monitoring namespace name |
| `kong_namespace` | Kong namespace name |
| `access_commands` | Commands to access services |
| `deployment_summary` | Summary of deployed components |
| `ingress_urls` | URLs for ingress-enabled services |

## 🔍 Monitoring Your Applications

### Adding Service Monitors

To monitor your application, add a ServiceMonitor:

```hcl
custom_service_monitors = {
  my-app = {
    selector = {
      matchLabels = {
        app = "my-application"
      }
    }
    endpoints = [
      {
        port     = "metrics"
        path     = "/metrics"
        interval = "30s"
      }
    ]
  }
}
```

### Adding Custom Alerts

Define custom alerting rules:

```hcl
custom_prometheus_rules = {
  my-alerts = {
    groups = [
      {
        name = "my-application"
        rules = [
          {
            alert = "ApplicationDown"
            expr  = "up{job=\"my-application\"} == 0"
            for   = "1m"
            labels = {
              severity = "critical"
            }
            annotations = {
              summary = "Application {{ $labels.instance }} is down"
            }
          }
        ]
      }
    ]
  }
}
```

## 🌐 Kong API Gateway

### Basic API Configuration

Kong is deployed in DB-less mode with a declarative configuration. To add APIs:

1. Create a ConfigMap with your Kong configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kong-declarative-config
  namespace: kong
data:
  kong.yml: |
    _format_version: "3.0"
    
    services:
    - name: my-api
      url: http://my-service.default.svc.cluster.local:8080
      routes:
      - name: my-api-route
        paths:
        - /api/v1
        strip_path: false
```

2. Update Kong to use the new configuration

### Using Kong Ingress Controller

If enabled, you can use standard Kubernetes Ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    kubernetes.io/ingress.class: kong
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

## 📈 Grafana Dashboards

Pre-installed dashboards include:
- Kubernetes cluster overview
- Node exporter metrics
- Pod and container metrics
- Kong API Gateway metrics
- Application performance monitoring

### Adding Custom Dashboards

1. Create dashboards in Grafana UI
2. Export the JSON
3. Add to a ConfigMap and mount in Grafana

## 🔔 Alerting

### Default Alerts

The module includes comprehensive alerting rules:
- Node and cluster health
- Pod resource utilization
- API server performance
- Storage and network issues

### Alertmanager Configuration

Configure alert routing in the Prometheus values template or provide custom configuration.

## 🏷️ Resource Tagging

All resources are tagged with:
- `cluster`: Cluster name
- `environment`: Environment name
- `managed-by`: "terraform"
- Component-specific labels

## 📦 Storage

### Storage Classes

The module can create optimized storage classes:
- **monitoring-ssd**: GP3 encrypted volumes for monitoring components

### Persistent Volumes

- Prometheus: Metrics storage
- Grafana: Dashboard and configuration storage  
- Alertmanager: Alert state storage
- Loki: Log storage (if enabled)

## 🔐 Security

### Pod Security

- Non-root containers
- Read-only root filesystems where possible
- Capability dropping
- Resource limits

### Network Security

- Internal service communication
- Configurable ingress access
- Security groups and network policies

## 🚨 Troubleshooting

### Common Issues

1. **PVC binding issues**: Check storage class availability
2. **Kong not starting**: Verify service account permissions
3. **Prometheus scraping failures**: Check ServiceMonitor selectors
4. **Grafana login issues**: Verify password configuration

### Debug Commands

```bash
# Check pod status
kubectl get pods -n monitoring
kubectl get pods -n kong

# Check service monitors
kubectl get servicemonitors -n monitoring

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-stack-prometheus-server 9090:80
# Visit: http://localhost:9090/targets

# Check logs
kubectl logs -n monitoring deployment/prometheus-stack-grafana
kubectl logs -n kong deployment/kong
```

## 🔄 Upgrades

To upgrade chart versions:

1. Update `*_chart_version` variables
2. Run `terraform plan` to review changes
3. Apply with `terraform apply`

For major version updates, check the chart's upgrade notes.

## 🤝 Contributing

When contributing to this module:

1. Test with multiple EKS versions
2. Validate resource limits for different cluster sizes
3. Update documentation for new features
4. Add examples for common use cases

## 📚 References

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Kong Helm Chart](https://github.com/Kong/charts)
- [Jaeger Helm Chart](https://github.com/jaegertracing/helm-charts)
- [Loki Helm Chart](https://github.com/grafana/helm-charts)
- [Prometheus Operator](https://prometheus-operator.dev/)

---

## 🎯 Quick Start Example

```bash
# 1. Configure the module
cat > monitoring.tf << EOF
module "monitoring" {
  source = "./modules/monitoring"
  
  cluster_name             = "my-cluster"
  environment              = "dev"
  grafana_admin_password   = "admin123"
  
  grafana_ingress_enabled  = true
  grafana_ingress_host     = "grafana.local"
}
EOF

# 2. Initialize and apply
terraform init
terraform plan
terraform apply

# 3. Access Grafana
kubectl port-forward -n monitoring svc/prometheus-stack-grafana 3000:80
# Open: http://localhost:3000 (admin/admin123)
```

Happy monitoring! 🚀
