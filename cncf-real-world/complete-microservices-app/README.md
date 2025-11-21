# Complete Microservices Application on Kubernetes

A production-ready e-commerce microservices application demonstrating all CNCF best practices.

## Architecture

```
                              Internet
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  Ingress (Nginx)│
                        │  + cert-manager │
                        └────────┬────────┘
                                 │
                   ┌─────────────┼─────────────┐
                   │             │             │
            ┌──────▼──────┐ ┌───▼────┐  ┌────▼─────┐
            │   Frontend  │ │  API   │  │  Admin   │
            │   (React)   │ │Gateway │  │  Portal  │
            └──────┬──────┘ └───┬────┘  └────┬─────┘
                   │            │            │
                   │      ┌─────▼─────┐      │
                   └─────▶│  Service  │◀─────┘
                          │   Mesh    │
                          │  (Istio)  │
                          └─────┬─────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
      ┌─────▼─────┐      ┌─────▼─────┐      ┌─────▼─────┐
      │  Product  │      │   Order   │      │   User    │
      │  Service  │      │  Service  │      │  Service  │
      └─────┬─────┘      └─────┬─────┘      └─────┬─────┘
            │                   │                   │
            │                   │                   │
      ┌─────▼─────┐      ┌─────▼─────┐      ┌─────▼─────┐
      │ PostgreSQL│      │ PostgreSQL│      │ PostgreSQL│
      │(StatefulSet)     │(StatefulSet)     │(StatefulSet)
      └───────────┘      └───────────┘      └───────────┘
            │                   │                   │
            └───────────────────┼───────────────────┘
                                │
                          ┌─────▼─────┐
                          │   Redis   │
                          │  (Cache)  │
                          └───────────┘
```

## Services

### 1. Frontend Service
- **Tech**: React SPA
- **Purpose**: Customer-facing web interface
- **Replicas**: 3 (HPA enabled)
- **Resources**: 100m CPU, 128Mi RAM

### 2. API Gateway
- **Tech**: Node.js/Express
- **Purpose**: Route requests, authentication, rate limiting
- **Replicas**: 3 (HPA enabled)
- **Resources**: 200m CPU, 256Mi RAM

### 3. Product Service
- **Tech**: Go
- **Purpose**: Product catalog, search, inventory
- **Database**: PostgreSQL
- **Cache**: Redis
- **Replicas**: 3

### 4. Order Service
- **Tech**: Python/FastAPI
- **Purpose**: Order processing, payments
- **Database**: PostgreSQL
- **Message Queue**: RabbitMQ
- **Replicas**: 3

### 5. User Service
- **Tech**: Java/Spring Boot
- **Purpose**: User management, authentication
- **Database**: PostgreSQL
- **Replicas**: 2

## Features Demonstrated

### Production Patterns
✅ **High Availability**: Multi-replica deployments with pod anti-affinity
✅ **Auto-scaling**: HPA based on CPU, memory, and custom metrics
✅ **Zero-downtime**: Rolling updates with health checks
✅ **Security**: RBAC, NetworkPolicies, Pod Security Standards
✅ **Observability**: Prometheus metrics, distributed tracing, logging
✅ **Service Mesh**: Istio for mTLS, traffic management
✅ **GitOps**: ArgoCD for continuous deployment
✅ **Stateful**: StatefulSets for databases with persistent storage
✅ **Secrets**: Sealed Secrets for encrypted secret management
✅ **Ingress**: Nginx Ingress with TLS termination

## Directory Structure

```
complete-microservices-app/
├── README.md (this file)
├── architecture-diagram.png
├── services/
│   ├── frontend/
│   │   ├── Dockerfile
│   │   ├── src/
│   │   └── k8s/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       └── hpa.yaml
│   ├── api-gateway/
│   │   ├── Dockerfile
│   │   ├── src/
│   │   └── k8s/
│   ├── product-service/
│   │   ├── Dockerfile
│   │   ├── main.go
│   │   └── k8s/
│   ├── order-service/
│   │   ├── Dockerfile
│   │   ├── main.py
│   │   └── k8s/
│   └── user-service/
│       ├── Dockerfile
│       ├── src/
│       └── k8s/
├── infrastructure/
│   ├── namespace.yaml
│   ├── istio/
│   │   ├── gateway.yaml
│   │   ├── virtual-service.yaml
│   │   └── destination-rules.yaml
│   ├── databases/
│   │   ├── postgres-product.yaml
│   │   ├── postgres-order.yaml
│   │   ├── postgres-user.yaml
│   │   └── redis.yaml
│   ├── ingress/
│   │   ├── nginx-ingress.yaml
│   │   └── certificates.yaml
│   └── monitoring/
│       ├── prometheus/
│       ├── grafana/
│       └── jaeger/
├── security/
│   ├── rbac.yaml
│   ├── network-policies.yaml
│   ├── pod-security-policy.yaml
│   └── sealed-secrets/
├── gitops/
│   ├── argocd-apps/
│   │   ├── frontend-app.yaml
│   │   ├── product-service-app.yaml
│   │   └── ...
│   └── kustomize/
│       ├── base/
│       └── overlays/
│           ├── dev/
│           ├── staging/
│           └── production/
└── scripts/
    ├── deploy.sh
    ├── setup-cluster.sh
    └── test-endpoints.sh
```

## Quick Start

### Prerequisites
```bash
# Tools needed
kubectl version --client  # >= 1.28
helm version             # >= 3.12
istioctl version        # >= 1.19
argocd version          # >= 2.8
```

### 1. Setup Cluster
```bash
# Create namespace
kubectl create namespace ecommerce

# Label namespace for Istio injection
kubectl label namespace ecommerce istio-injection=enabled

# Label for Pod Security Standards
kubectl label namespace ecommerce \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### 2. Install Dependencies
```bash
# Install Istio
cd scripts
./install-istio.sh

# Install monitoring stack
./install-monitoring.sh

# Install ArgoCD
./install-argocd.sh
```

### 3. Deploy Application
```bash
# Option 1: Direct kubectl apply
kubectl apply -k gitops/kustomize/overlays/production

# Option 2: Using ArgoCD (recommended)
argocd app create ecommerce \
  --repo https://github.com/yourusername/ecommerce \
  --path gitops/kustomize/overlays/production \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ecommerce \
  --sync-policy automated \
  --self-heal \
  --auto-prune

argocd app sync ecommerce
```

### 4. Verify Deployment
```bash
# Check pods
kubectl get pods -n ecommerce

# Check services
kubectl get svc -n ecommerce

# Check ingress
kubectl get ingress -n ecommerce

# Test endpoints
./scripts/test-endpoints.sh
```

### 5. Access Application
```bash
# Get Istio Ingress Gateway external IP
kubectl get svc -n istio-system istio-ingressgateway

# Access via browser
https://ecommerce.yourdomain.com

# Access monitoring
https://grafana.yourdomain.com
https://jaeger.yourdomain.com
```

## Testing Scenarios

### 1. High Availability Test
```bash
# Delete a pod and watch it recover
kubectl delete pod -n ecommerce -l app=product-service

# Watch pods
kubectl get pods -n ecommerce -w
```

### 2. Auto-scaling Test
```bash
# Generate load
kubectl run -it --rm load-generator --image=busybox /bin/sh
# Inside pod:
while true; do wget -q -O- http://product-service.ecommerce.svc.cluster.local/products; done

# Watch HPA
kubectl get hpa -n ecommerce -w
```

### 3. Canary Deployment Test
```bash
# Deploy v2 with 10% traffic
kubectl apply -f services/product-service/k8s/canary-v2.yaml

# Monitor traffic split in Kiali
# Gradually increase to 50%, then 100%
```

### 4. Chaos Engineering Test
```bash
# Install Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh --namespace=chaos-mesh

# Inject network delay
kubectl apply -f tests/chaos/network-delay.yaml

# Inject pod failure
kubectl apply -f tests/chaos/pod-kill.yaml
```

## Observability

### Metrics (Prometheus)
```bash
# Access Prometheus
kubectl port-forward -n monitoring svc/prometheus-k8s 9090:9090

# Example queries:
# - Request rate: rate(http_requests_total[5m])
# - Error rate: rate(http_requests_total{status=~"5.."}[5m])
# - Latency: histogram_quantile(0.99, http_request_duration_seconds_bucket)
```

### Dashboards (Grafana)
```bash
# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Pre-configured dashboards:
# - Application Overview
# - Service Performance
# - Database Metrics
# - Istio Service Mesh
# - Kubernetes Cluster
```

### Tracing (Jaeger)
```bash
# Access Jaeger
kubectl port-forward -n monitoring svc/jaeger-query 16686:16686

# View traces for a complete request flow
```

### Logs (Loki)
```bash
# Query logs
kubectl port-forward -n monitoring svc/loki 3100:3100

# LogQL examples:
# - {app="product-service"} |= "error"
# - rate({namespace="ecommerce"}[5m])
```

## Security Features

### 1. RBAC
- Service accounts per service
- Minimal permissions (least privilege)
- No default service account usage

### 2. Network Policies
- Default deny all traffic
- Explicit allow rules
- Namespace isolation
- External access restricted

### 3. Pod Security
- Non-root containers
- Read-only root filesystem
- Drop all capabilities
- Run as non-root user
- Seccomp profile

### 4. Secrets Management
- Sealed Secrets for Git storage
- External Secrets Operator (optional)
- Vault integration (optional)

### 5. mTLS (Istio)
- Automatic mutual TLS
- Certificate rotation
- Authorization policies

## Performance Optimization

### Resource Requests/Limits
All services have appropriate requests and limits set based on profiling:
- **Frontend**: 100m/200m CPU, 128Mi/256Mi RAM
- **API Gateway**: 200m/500m CPU, 256Mi/512Mi RAM
- **Product Service**: 300m/1000m CPU, 512Mi/1Gi RAM
- **Order Service**: 500m/1500m CPU, 1Gi/2Gi RAM
- **User Service**: 200m/500m CPU, 512Mi/1Gi RAM

### Caching Strategy
- Redis for session storage
- Redis for product catalog cache
- HTTP caching headers
- CDN for static assets

### Database Optimization
- Connection pooling (PgBouncer)
- Read replicas for read-heavy workloads
- Proper indexes
- Query optimization

## Cost Optimization

### Strategies Implemented
1. **Horizontal Pod Autoscaler**: Scale based on demand
2. **Cluster Autoscaler**: Add/remove nodes automatically
3. **Spot Instances**: For non-critical workloads
4. **Resource Right-sizing**: Based on actual usage
5. **Caching**: Reduce database load
6. **CDN**: Reduce bandwidth costs

### Estimated Costs (GKE example)
```
Cluster:
- 3 x n2-standard-4 (on-demand): $292/month
- 5 x n2-standard-4 (spot): $73/month
- Storage (500GB): $80/month
- Load Balancer: $18/month
- Total: ~$463/month

AWS EKS would be similar, Azure AKS control plane is free.
```

## Disaster Recovery

### Backup Strategy
```bash
# Install Velero
velero install \
  --provider aws \
  --bucket my-backup-bucket \
  --secret-file ./credentials-velero

# Create backup
velero backup create ecommerce-backup \
  --include-namespaces ecommerce \
  --snapshot-volumes

# Schedule daily backups
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --include-namespaces ecommerce
```

### Recovery
```bash
# Restore from backup
velero restore create --from-backup ecommerce-backup

# Verify
kubectl get pods -n ecommerce
```

## CI/CD Pipeline

### GitHub Actions Example
```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Docker image
        run: docker build -t myregistry/product-service:${{ github.sha }} .
      - name: Push to registry
        run: docker push myregistry/product-service:${{ github.sha }}
      - name: Update image in GitOps repo
        run: |
          yq eval '.spec.template.spec.containers[0].image = "myregistry/product-service:${{ github.sha }}"' \
            -i k8s/deployment.yaml
          git commit -am "Update image to ${{ github.sha }}"
          git push
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n ecommerce
   kubectl logs <pod-name> -n ecommerce
   ```

2. **Service not accessible**
   ```bash
   kubectl get svc -n ecommerce
   kubectl get endpoints -n ecommerce
   kubectl get networkpolicies -n ecommerce
   ```

3. **Istio issues**
   ```bash
   istioctl analyze -n ecommerce
   kubectl logs -n ecommerce <pod-name> -c istio-proxy
   ```

4. **Database connection issues**
   ```bash
   kubectl exec -it <pod-name> -n ecommerce -- psql -h postgres-service -U dbuser -d dbname
   ```

## Next Steps

1. **Add more services**: Payment, Notification, Analytics
2. **Implement CI/CD**: Complete pipeline with testing
3. **Add chaos engineering**: Chaos Mesh experiments
4. **Multi-cluster**: Deploy across multiple clusters
5. **Service mesh advanced**: Circuit breakers, retries, timeouts
6. **Advanced monitoring**: SLO/SLA tracking
7. **Performance testing**: k6 or Locust load tests
8. **Security scanning**: Trivy, Falco, OPA policies

## References

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [Istio Documentation](https://istio.io/latest/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [CNCF Landscape](https://landscape.cncf.io/)
