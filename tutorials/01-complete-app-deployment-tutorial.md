# Tutorial: Deploy Complete Production App from Zero to Hero

**Duration:** 4-6 hours
**Difficulty:** Intermediate to Advanced
**Prerequisites:** AWS account, basic Kubernetes knowledge

This tutorial will guide you through deploying a complete production-ready application using all the content in this repository.

## Table of Contents

1. [Setup AWS Infrastructure with Terraform](#step-1-aws-infrastructure)
2. [Deploy Kubernetes Cluster](#step-2-kubernetes-cluster)
3. [Configure Servers with Ansible](#step-3-ansible-configuration)
4. [Deploy Microservices Application](#step-4-microservices-deployment)
5. [Setup Monitoring and Observability](#step-5-monitoring)
6. [Implement GitOps with ArgoCD](#step-6-gitops)
7. [Test and Validate](#step-7-testing)
8. [Cleanup](#step-8-cleanup)

---

## Step 1: AWS Infrastructure with Terraform

### 1.1 Prepare Your Environment

```bash
# Install required tools
brew install terraform awscli kubectl helm

# Configure AWS credentials
aws configure
# Enter your access key, secret key, region (us-east-1), and output format (json)

# Verify AWS access
aws sts get-caller-identity
```

### 1.2 Setup Terraform State Backend

```bash
# Create S3 bucket for Terraform state
export AWS_REGION=us-east-1
export STATE_BUCKET=my-terraform-state-$(date +%s)

aws s3api create-bucket \
  --bucket $STATE_BUCKET \
  --region $AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $STATE_BUCKET \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket $STATE_BUCKET \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

echo "State bucket: $STATE_BUCKET"
```

### 1.3 Deploy VPC and Networking

```bash
# Navigate to terraform directory
cd terraform-mastery/aws/complete-app

# Copy and edit variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
cat > terraform.tfvars <<EOF
aws_region   = "us-east-1"
environment  = "production"
project_name = "myapp"
domain_name  = "example.com"

# Database (use strong passwords in production!)
db_password = "ChangeMe123!StrongPassword"

# Redis
redis_auth_token = "ChangeMe123!RedisToken"

# Container image (we'll build this later)
container_image = "nginx:latest"  # placeholder

# Monitoring
alert_email = "your-email@example.com"
EOF

# Update backend configuration
sed -i '' "s/my-terraform-state-bucket/$STATE_BUCKET/" main.tf

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Review the plan carefully
# You should see:
# - VPC with 3 AZs
# - Public and private subnets
# - NAT gateways
# - RDS PostgreSQL
# - ElastiCache Redis
# - ALB
# - ECS cluster
# - S3 buckets
# - CloudFront distribution

# Apply (this will take 10-15 minutes)
terraform apply tfplan
```

**Expected Output:**
```
Apply complete! Resources: 67 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "myapp-production-alb-1234567890.us-east-1.elb.amazonaws.com"
cloudfront_domain_name = "d1234567890.cloudfront.net"
rds_endpoint = "myapp-production-db.c1234567890.us-east-1.rds.amazonaws.com"
redis_endpoint = "myapp-production-redis.abc123.0001.use1.cache.amazonaws.com"
vpc_id = "vpc-0123456789abcdef0"
```

### 1.4 Verify Infrastructure

```bash
# Check VPC
aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=myapp" \
  --query 'Vpcs[0].[VpcId,CidrBlock,State]' \
  --output table

# Check RDS
aws rds describe-db-instances \
  --db-instance-identifier myapp-production-db \
  --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus,Endpoint.Address]' \
  --output table

# Check load balancer
aws elbv2 describe-load-balancers \
  --names myapp-production-alb \
  --query 'LoadBalancers[0].[LoadBalancerName,State.Code,DNSName]' \
  --output table
```

**Time Check:** ✅ 30 minutes elapsed

---

## Step 2: Kubernetes Cluster with EKS

### 2.1 Deploy EKS Cluster

```bash
# Navigate to multi-cloud K8s directory
cd ../../multi-cloud/k8s-cluster

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
environment  = "production"
aws_region   = "us-east-1"
deploy_aws   = true
deploy_azure = false
deploy_gcp   = false
EOF

# Initialize and deploy
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# This will take 15-20 minutes
```

### 2.2 Configure kubectl

```bash
# Get kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name production-k8s-aws

# Verify connection
kubectl get nodes

# Expected output:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123.ec2.internal    Ready    <none>   5m    v1.28.x
# ip-10-0-2-124.ec2.internal    Ready    <none>   5m    v1.28.x
# ip-10-0-3-125.ec2.internal    Ready    <none>   5m    v1.28.x
```

### 2.3 Install Essential Add-ons

```bash
# Install metrics server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait for metrics server
kubectl wait --for=condition=ready pod \
  -l k8s-app=metrics-server \
  -n kube-system \
  --timeout=300s

# Verify
kubectl top nodes
```

**Time Check:** ✅ 1 hour elapsed

---

## Step 3: Configure with Ansible

### 3.1 Setup Ansible Control Node

```bash
# Navigate to ansible directory
cd ../../../ansible-mastery

# Install Ansible
pip3 install ansible

# Create inventory
cat > inventory/production.ini <<EOF
[k8s_master]
master1 ansible_host=10.0.1.10 ansible_user=ubuntu

[k8s_workers]
worker1 ansible_host=10.0.2.10 ansible_user=ubuntu
worker2 ansible_host=10.0.2.11 ansible_user=ubuntu
worker3 ansible_host=10.0.2.12 ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_private_key_file=~/.ssh/your-key.pem
EOF
```

### 3.2 Apply Common Role

```bash
# Test connectivity
ansible all -i inventory/production.ini -m ping

# Run common role
ansible-playbook -i inventory/production.ini \
  playbooks/common-setup.yml

# Expected tasks:
# - Update packages
# - Configure SSH
# - Setup firewall
# - Configure NTP
# - Install monitoring agents
```

### 3.3 Deploy Application Dependencies

```bash
# Deploy PostgreSQL if needed (for services running on VMs)
ansible-playbook -i inventory/production.ini \
  playbooks/postgres-setup.yml \
  -e "postgres_version=14"

# Deploy monitoring stack
ansible-playbook -i inventory/production.ini \
  playbooks/monitoring-setup.yml
```

**Time Check:** ✅ 1.5 hours elapsed

---

## Step 4: Deploy Microservices Application

### 4.1 Prepare Application

```bash
# Navigate to microservices app
cd ../cncf-real-world/complete-microservices-app

# Create namespace
kubectl create namespace ecommerce

# Label namespace for Istio
kubectl label namespace ecommerce istio-injection=enabled

# Apply Pod Security Standards
kubectl label namespace ecommerce \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

### 4.2 Deploy Infrastructure Components

```bash
# Deploy PostgreSQL for product service
kubectl apply -f infrastructure/databases/postgres-product.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod \
  -l app=postgres-product \
  -n ecommerce \
  --timeout=300s

# Deploy Redis for caching
kubectl apply -f infrastructure/databases/redis.yaml

# Wait for Redis
kubectl wait --for=condition=ready pod \
  -l app=redis \
  -n ecommerce \
  --timeout=300s

# Verify databases
kubectl get pods -n ecommerce
```

### 4.3 Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Build product service
cd services/product-service
docker build -t product-service:v1.0.0 .

# Tag and push
docker tag product-service:v1.0.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/product-service:v1.0.0

docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/product-service:v1.0.0

# Update deployment with correct image
sed -i '' 's|myregistry/product-service:v1.0.0|123456789012.dkr.ecr.us-east-1.amazonaws.com/product-service:v1.0.0|' \
  k8s/deployment.yaml
```

### 4.4 Deploy Product Service

```bash
# Deploy the service
kubectl apply -f k8s/deployment.yaml

# Watch pods come up
kubectl get pods -n ecommerce -w

# Expected output:
# NAME                               READY   STATUS    RESTARTS   AGE
# product-service-7d9f8b5c4d-2xwkr   2/2     Running   0          30s
# product-service-7d9f8b5c4d-8qvnm   2/2     Running   0          30s
# product-service-7d9f8b5c4d-mzp4k   2/2     Running   0          30s
```

### 4.5 Verify Deployment

```bash
# Check service
kubectl get svc -n ecommerce

# Port forward to test
kubectl port-forward -n ecommerce \
  svc/product-service 8080:80 &

# Test endpoints
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
curl http://localhost:8080/api/v1/products

# Stop port forward
kill %1
```

**Time Check:** ✅ 2.5 hours elapsed

---

## Step 5: Setup Monitoring

### 5.1 Install Prometheus Stack

```bash
# Add Helm repo
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts
helm repo update

# Install kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword='StrongPassword123!'

# Wait for pods
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n monitoring \
  --timeout=300s
```

### 5.2 Access Grafana

```bash
# Port forward to Grafana
kubectl port-forward -n monitoring \
  svc/prometheus-grafana 3000:80 &

# Open browser to http://localhost:3000
# Login: admin / StrongPassword123!

echo "Grafana URL: http://localhost:3000"
echo "Username: admin"
echo "Password: StrongPassword123!"
```

### 5.3 Install Jaeger for Tracing

```bash
# Install Jaeger operator
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/latest/download/jaeger-operator.yaml -n observability

# Deploy Jaeger instance
cat <<EOF | kubectl apply -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: monitoring
spec:
  strategy: production
  storage:
    type: elasticsearch
    options:
      es:
        server-urls: http://elasticsearch:9200
EOF

# Port forward to Jaeger UI
kubectl port-forward -n monitoring \
  svc/jaeger-query 16686:16686 &

echo "Jaeger URL: http://localhost:16686"
```

### 5.4 Configure Alerts

```bash
# Create PrometheusRule for alerts
kubectl apply -f infrastructure/monitoring/prometheus/alerts.yaml

# Verify alerts
kubectl get prometheusrules -n monitoring
```

**Time Check:** ✅ 3 hours elapsed

---

## Step 6: Implement GitOps with ArgoCD

### 6.1 Install ArgoCD

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s

# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

echo "ArgoCD URL: https://localhost:8080"
echo "Username: admin"
echo "Password: [output from above command]"
```

### 6.2 Create ArgoCD Application

```bash
# Login to ArgoCD CLI
argocd login localhost:8080 --insecure

# Create application
argocd app create product-service \
  --repo https://github.com/yourorg/ecommerce \
  --path cncf-real-world/complete-microservices-app/services/product-service/k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ecommerce \
  --sync-policy automated \
  --auto-prune \
  --self-heal

# Sync application
argocd app sync product-service

# Watch sync status
argocd app wait product-service
```

### 6.3 Verify GitOps

```bash
# Make a change to deployment
# Edit k8s/deployment.yaml and commit to Git

# ArgoCD will automatically detect and sync the change
argocd app get product-service

# View sync history
argocd app history product-service
```

**Time Check:** ✅ 3.5 hours elapsed

---

## Step 7: Test and Validate

### 7.1 Load Testing

```bash
# Install k6
brew install k6

# Create load test script
cat > load-test.js <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '3m', target: 50 },
    { duration: '1m', target: 0 },
  ],
};

export default function () {
  let res = http.get('http://localhost:8080/api/v1/products');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  sleep(1);
}
EOF

# Run load test
k6 run load-test.js

# Watch auto-scaling
kubectl get hpa -n ecommerce -w
```

### 7.2 Chaos Engineering

```bash
# Install Chaos Mesh
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm install chaos-mesh chaos-mesh/chaos-mesh \
  --namespace chaos-mesh \
  --create-namespace

# Create pod kill experiment
cat <<EOF | kubectl apply -f -
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill-product-service
  namespace: ecommerce
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces:
      - ecommerce
    labelSelectors:
      app: product-service
  scheduler:
    cron: '@every 5m'
EOF

# Watch recovery
kubectl get pods -n ecommerce -w
```

### 7.3 Verify Observability

```bash
# Check Prometheus targets
open http://localhost:9090/targets

# View Grafana dashboards
open http://localhost:3000/dashboards

# View Jaeger traces
open http://localhost:16686

# Check logs
kubectl logs -n ecommerce -l app=product-service --tail=100
```

### 7.4 Security Validation

```bash
# Run security scan with Trivy
trivy image 123456789012.dkr.ecr.us-east-1.amazonaws.com/product-service:v1.0.0

# Check Pod Security Standards
kubectl get pods -n ecommerce -o json | \
  jq '.items[].spec.securityContext'

# Verify network policies
kubectl get networkpolicies -n ecommerce
```

**Time Check:** ✅ 4 hours elapsed

---

## Step 8: Cleanup

### 8.1 Delete Kubernetes Resources

```bash
# Delete ArgoCD applications
argocd app delete product-service

# Delete namespaces
kubectl delete namespace ecommerce
kubectl delete namespace monitoring
kubectl delete namespace argocd

# Delete EKS cluster
cd terraform-mastery/multi-cloud/k8s-cluster
terraform destroy -auto-approve
```

### 8.2 Delete AWS Infrastructure

```bash
# Delete application stack
cd ../aws/complete-app
terraform destroy -auto-approve

# This will take 10-15 minutes
```

### 8.3 Cleanup State

```bash
# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-locks

# Delete S3 bucket
aws s3 rb s3://$STATE_BUCKET --force
```

---

## 🎉 Congratulations!

You have successfully:

✅ Deployed AWS infrastructure with Terraform
✅ Created a production Kubernetes cluster
✅ Configured servers with Ansible
✅ Deployed a microservices application
✅ Setup complete observability stack
✅ Implemented GitOps with ArgoCD
✅ Tested with load and chaos engineering

## Next Steps

1. **Multi-Region**: Deploy to multiple AWS regions
2. **Multi-Cloud**: Add Azure and GCP deployments
3. **Advanced Monitoring**: Add SLIs/SLOs
4. **Cost Optimization**: Implement Spot instances, auto-scaling schedules
5. **CI/CD**: Add GitHub Actions pipeline
6. **Security**: Implement WAF, GuardDuty, Security Hub

## Troubleshooting

### Issue: Terraform apply fails

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform logs
export TF_LOG=DEBUG
terraform apply

# Destroy and retry
terraform destroy -auto-approve
terraform apply
```

### Issue: Pods not starting

**Solution:**
```bash
# Describe pod
kubectl describe pod <pod-name> -n ecommerce

# Check logs
kubectl logs <pod-name> -n ecommerce

# Check events
kubectl get events -n ecommerce --sort-by='.lastTimestamp'
```

### Issue: High costs

**Solution:**
```bash
# Check AWS Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Scale down non-production
kubectl scale deployment -n ecommerce --replicas=1 --all

# Use Spot instances
# Update Terraform to use Spot for ECS tasks
```

## Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [CNCF Landscape](https://landscape.cncf.io/)
- [Terraform Registry](https://registry.terraform.io/)
- [Ansible Galaxy](https://galaxy.ansible.com/)

**Total Time:** 4-6 hours depending on experience level
