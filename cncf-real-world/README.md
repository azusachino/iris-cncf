# CNCF Real-World Scenarios

Production-ready Kubernetes and cloud-native patterns for real-world applications.

## 🎯 What This Section Covers

You already know basic Kubernetes concepts (Pods, Deployments, Services). This section focuses on:
- **Production deployment strategies** (blue-green, canary, progressive)
- **Advanced networking** (Service mesh, Ingress controllers, Network policies)
- **Observability at scale** (Prometheus, Grafana, Jaeger, OpenTelemetry)
- **Security hardening** (Pod Security, RBAC, Policy engines, mTLS)
- **Storage patterns** (StatefulSets, operators, backup strategies)
- **GitOps workflows** (ArgoCD, Flux, automated deployments)
- **CI/CD pipelines** (Tekton, GitHub Actions, integrated workflows)

## 📚 Learning Path

### Week 1: Production Deployments
- Advanced Deployment strategies
- Rolling updates, blue-green, canary
- Progressive delivery with Flagger
- Helm charts and Kustomize

### Week 2: Observability
- Prometheus metrics and alerting
- Grafana dashboards
- Distributed tracing with Jaeger
- Log aggregation with Loki/EFK

### Week 3: Security
- Pod Security Standards
- Network Policies
- RBAC best practices
- Policy enforcement (OPA/Kyverno)
- Image scanning and admission control

### Week 4: Networking
- Ingress controllers (Nginx, Traefik)
- Service mesh introduction (Istio/Linkerd)
- mTLS and traffic management
- Multi-cluster networking

### Week 5: Storage & Stateful Apps
- StatefulSets patterns
- Database operators (PostgreSQL, MySQL)
- Volume snapshots and backup
- Disaster recovery

### Week 6: GitOps & CI/CD
- GitOps principles
- ArgoCD for continuous deployment
- Tekton pipelines
- End-to-end workflows

## 🏗️ Reference Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Internet / Users                        │
└────────────────────────────┬────────────────────────────────┘
                             │
                     ┌───────▼──────┐
                     │  Ingress     │  (Nginx/Traefik + cert-manager)
                     │  Controller  │
                     └───────┬──────┘
                             │
                 ┌───────────┴───────────┐
                 │                       │
         ┌───────▼──────┐        ┌──────▼──────┐
         │   Frontend   │        │   API       │
         │   Service    │        │   Gateway   │
         └───────┬──────┘        └──────┬──────┘
                 │                      │
         ┌───────▼──────────────────────▼───────┐
         │         Service Mesh (Istio)         │
         │  (mTLS, Traffic Management, Tracing) │
         └───────┬──────────────────────┬───────┘
                 │                      │
    ┌────────────┴────────┐    ┌────────┴──────────┐
    │  Microservice A     │    │  Microservice B   │
    │  (Deployment)       │    │  (StatefulSet)    │
    └────────────┬────────┘    └────────┬──────────┘
                 │                      │
         ┌───────▼──────────────────────▼──────┐
         │     Database / Cache / Queue        │
         │  (PostgreSQL, Redis, RabbitMQ)      │
         └─────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│              Observability Layer                             │
│  ┌─────────────┐  ┌──────────┐  ┌───────────┐              │
│  │ Prometheus  │  │  Jaeger  │  │   Loki    │              │
│  │  (Metrics)  │  │ (Traces) │  │  (Logs)   │              │
│  └──────┬──────┘  └─────┬────┘  └─────┬─────┘              │
│         └────────────────┼─────────────┘                     │
│                    ┌─────▼─────┐                            │
│                    │  Grafana  │                            │
│                    └───────────┘                            │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                   GitOps Layer                               │
│  ┌────────────┐         ┌──────────────┐                    │
│  │   GitHub   │ ──────> │   ArgoCD     │ ───> K8s Cluster  │
│  │ (Git Repo) │         │ (CD Operator)│                    │
│  └────────────┘         └──────────────┘                    │
└──────────────────────────────────────────────────────────────┘
```

## 🎓 Directory Structure

```
cncf-real-world/
├── deployments/          # Deployment strategies and patterns
│   ├── blue-green/      # Blue-green deployment examples
│   ├── canary/          # Canary deployment with Flagger
│   ├── progressive/     # Progressive delivery
│   └── helm-charts/     # Production Helm charts
│
├── monitoring/           # Observability stack
│   ├── prometheus/      # Prometheus setup and alerts
│   ├── grafana/         # Dashboards and visualizations
│   ├── jaeger/          # Distributed tracing
│   └── opentelemetry/   # OpenTelemetry instrumentation
│
├── security/             # Security patterns
│   ├── rbac/            # Role-based access control
│   ├── network-policies/ # Network security
│   ├── pod-security/    # Pod Security Standards
│   ├── opa/             # Open Policy Agent
│   └── falco/           # Runtime security
│
├── networking/           # Advanced networking
│   ├── ingress/         # Ingress controllers
│   ├── service-mesh/    # Istio/Linkerd examples
│   ├── multi-cluster/   # Multi-cluster patterns
│   └── network-policies/ # Network segmentation
│
├── storage/              # Persistent storage patterns
│   ├── statefulsets/    # StatefulSet examples
│   ├── operators/       # Database operators
│   ├── backup/          # Velero backup strategies
│   └── csi-drivers/     # CSI driver configurations
│
├── ci-cd/                # CI/CD pipelines
│   ├── tekton/          # Tekton pipelines
│   ├── github-actions/  # GitHub Actions workflows
│   ├── gitlab-ci/       # GitLab CI examples
│   └── jenkins-x/       # Jenkins X patterns
│
├── service-mesh/         # Service mesh deep dive
│   ├── istio/           # Istio configuration
│   ├── linkerd/         # Linkerd setup
│   ├── traffic-mgmt/    # Traffic management
│   └── security/        # mTLS and security
│
└── gitops/               # GitOps workflows
    ├── argocd/          # ArgoCD applications
    ├── flux/            # Flux CD examples
    ├── multi-env/       # Multi-environment setup
    └── progressive-sync/ # Progressive deployment
```

## 💡 Key Concepts for Production

### 1. Resource Management
- **Requests vs Limits**: Set appropriate values
- **QoS Classes**: Guaranteed, Burstable, BestEffort
- **LimitRanges**: Default limits per namespace
- **ResourceQuotas**: Limit namespace resources

### 2. High Availability
- **Pod Disruption Budgets**: Maintain availability during voluntary disruptions
- **Pod Anti-Affinity**: Spread pods across nodes/zones
- **Multiple Replicas**: At least 3 for critical services
- **Multi-AZ Deployment**: Distribute across availability zones

### 3. Security
- **Principle of Least Privilege**: Minimal RBAC permissions
- **Non-Root Containers**: Run as non-root user
- **Read-Only Root Filesystem**: Prevent runtime modification
- **Drop Capabilities**: Remove unnecessary Linux capabilities
- **Network Policies**: Explicit allow-list networking

### 4. Observability
- **Metrics**: Prometheus for metrics collection
- **Logs**: Centralized logging (EFK, Loki)
- **Traces**: Distributed tracing (Jaeger, Zipkin)
- **Dashboards**: Grafana for visualization
- **Alerting**: Proactive alerting based on SLIs

### 5. GitOps
- **Single Source of Truth**: Git repository
- **Declarative Configuration**: Kubernetes manifests
- **Automated Sync**: ArgoCD/Flux
- **Immutable Infrastructure**: No manual changes
- **Audit Trail**: Git history

## 🚀 Getting Started

### Prerequisites
```bash
# Install required tools
kubectl version --client
helm version
kustomize version
argocd version
```

### Setup Local Cluster
```bash
# Kind cluster with ingress
kind create cluster --config=kind-config.yaml

# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### Deploy Sample Application
```bash
# Deploy microservices demo
kubectl apply -f cncf-real-world/deployments/microservices-demo/

# Install monitoring stack
kubectl apply -f cncf-real-world/monitoring/kube-prometheus-stack/

# Setup GitOps
kubectl apply -f cncf-real-world/gitops/argocd/install.yaml
```

## 📖 Scenarios Covered

### Scenario 1: Zero-Downtime Deployment
Deploy a new version of an application with zero downtime using rolling updates and health checks.

### Scenario 2: Canary Deployment
Gradually roll out a new version to a subset of users using Flagger and Istio.

### Scenario 3: Multi-Tenant Cluster
Isolate workloads in a shared cluster using namespaces, RBAC, and network policies.

### Scenario 4: Auto-Scaling Application
Scale application based on CPU, memory, and custom metrics using HPA and VPA.

### Scenario 5: Disaster Recovery
Backup and restore cluster state and persistent data using Velero.

### Scenario 6: Service Mesh Migration
Migrate existing services to Istio with mTLS and observability.

### Scenario 7: GitOps Pipeline
Set up end-to-end GitOps workflow with ArgoCD for multiple environments.

### Scenario 8: Database Operator
Deploy and manage PostgreSQL using an operator with automated backups.

### Scenario 9: Security Hardening
Implement Pod Security Standards, Network Policies, and OPA policies.

### Scenario 10: Multi-Cluster Federation
Connect multiple clusters for disaster recovery and geographic distribution.

## 🎯 Certification Alignment

### CKA (Certified Kubernetes Administrator)
- Cluster architecture and installation
- Workload management
- Services and networking
- Storage
- Troubleshooting

### CKAD (Certified Kubernetes Application Developer)
- Application design and build
- Application deployment
- Application observability and maintenance
- Application environment, configuration, and security
- Services and networking

### CKS (Certified Kubernetes Security Specialist)
- Cluster setup and hardening
- System hardening
- Minimize microservice vulnerabilities
- Supply chain security
- Monitoring, logging, and runtime security

## 📝 Best Practices Checklist

- [ ] Use namespaces for resource isolation
- [ ] Set resource requests and limits
- [ ] Configure liveness and readiness probes
- [ ] Use init containers for setup tasks
- [ ] Implement Pod Disruption Budgets
- [ ] Configure pod anti-affinity for HA
- [ ] Use secrets for sensitive data
- [ ] Enable RBAC with least privilege
- [ ] Implement network policies
- [ ] Use read-only root filesystem
- [ ] Run containers as non-root
- [ ] Scan images for vulnerabilities
- [ ] Set up monitoring and alerting
- [ ] Implement centralized logging
- [ ] Use GitOps for deployments
- [ ] Automate with CI/CD pipelines
- [ ] Regular backup and DR testing
- [ ] Document runbooks and procedures

## 🔗 Additional Resources

- **CNCF Landscape**: https://landscape.cncf.io/
- **Kubernetes Patterns**: https://k8spatterns.io/
- **Production Best Practices**: https://kubernetes.io/docs/setup/best-practices/
- **Security Best Practices**: https://kubernetes.io/docs/concepts/security/

Start with the deployment strategies and work through each section systematically!
