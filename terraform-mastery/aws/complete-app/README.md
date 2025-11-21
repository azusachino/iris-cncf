# Complete AWS Application Stack with Terraform

Production-ready 3-tier web application infrastructure on AWS.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                  ┌──────▼──────┐
                  │  Route 53   │
                  │    (DNS)    │
                  └──────┬──────┘
                         │
      ┌──────────────────┼──────────────────┐
      │                  │                  │
┌─────▼─────┐      ┌────▼────┐      ┌─────▼─────┐
│CloudFront │      │   WAF   │      │  Shield   │
│   (CDN)   │      │         │      │   (DDoS)  │
└─────┬─────┘      └────┬────┘      └─────┬─────┘
      │                  │                  │
      │           ┌──────▼──────┐          │
      │           │     ALB     │◀─────────┘
      │           │  (us-east-1)│
      │           └──────┬──────┘
      │                  │
      │     ┌────────────┼────────────┐
      │     │            │            │
      │  ┌──▼──┐      ┌──▼──┐      ┌──▼──┐
      │  │ ECS │      │ ECS │      │ ECS │
      │  │Task │      │Task │      │Task │
      │  │(1a) │      │(1b) │      │(1c) │
      │  └──┬──┘      └──┬──┘      └──┬──┘
      │     │            │            │
      │     └────────────┼────────────┘
      │                  │
      │        ┌─────────┼─────────┐
      │        │         │         │
      │    ┌───▼──┐  ┌───▼───┐ ┌──▼───┐
      │    │  RDS │  │ Redis │ │  S3  │◀──┘
      │    │      │  │ Cluster│ │      │
      │    │Multi │  │        │ │Static│
      │    │  AZ  │  │Multi-AZ│ │Assets│
      │    └──────┘  └────────┘ └──────┘
      │
      └────▶ CloudFront ────▶ S3 Static Assets
```

## Components

### Networking
- **VPC**: Isolated network with public, private, and database subnets across 3 AZs
- **NAT Gateways**: Multi-AZ NAT for high availability (or single for dev)
- **VPC Endpoints**: S3, ECR, ECS, Secrets Manager, etc.
- **Security Groups**: Least-privilege network access

### Compute
- **ECS Fargate**: Serverless container orchestration
- **Application Load Balancer**: Layer 7 load balancing with HTTPS
- **Auto Scaling**: CPU and memory-based scaling (2-20 tasks)

### Data
- **RDS PostgreSQL**: Multi-AZ deployment with automated backups
- **ElastiCache Redis**: Multi-AZ Redis cluster for caching
- **S3**: Static assets and ALB logs

### CDN & DNS
- **CloudFront**: Global CDN for static assets
- **Route 53**: DNS management
- **ACM**: SSL/TLS certificates

### Monitoring & Security
- **CloudWatch**: Logs, metrics, and alarms
- **KMS**: Encryption keys for RDS and secrets
- **IAM**: Least-privilege roles for all services
- **VPC Flow Logs**: Network traffic logging

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.5.0
3. **AWS CLI** configured with credentials
4. **S3 Bucket** for Terraform state (create first)
5. **DynamoDB Table** for state locking
6. **Domain name** registered in Route 53

## Quick Start

### 1. Setup State Backend

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket my-terraform-state-bucket \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Configure Variables

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Important:** Update these values:
- `db_password`: Strong password (use AWS Secrets Manager in production)
- `redis_auth_token`: Strong token
- `container_image`: Your ECR image
- `domain_name`: Your domain
- `alert_email`: Your email for alerts

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Plan Deployment

```bash
# Preview changes
terraform plan -out=tfplan

# Review the plan carefully
```

### 5. Deploy

```bash
# Apply changes
terraform apply tfplan

# Note down the outputs
```

### 6. Verify Deployment

```bash
# Check ALB endpoint
terraform output alb_dns_name

# Check CloudFront URL
terraform output cloudfront_domain_name

# Test application
curl https://$(terraform output -raw alb_dns_name)/health
```

## Project Structure

```
aws/complete-app/
├── README.md (this file)
├── main.tf              # Main infrastructure
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── versions.tf          # Provider versions
├── terraform.tfvars.example  # Example variables
├── modules/             # Custom modules (if any)
│   ├── ecs/
│   ├── monitoring/
│   └── security/
└── scripts/
    ├── deploy.sh        # Deployment script
    └── destroy.sh       # Cleanup script
```

## Estimated Costs

### Production Environment (us-east-1)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **ECS Fargate** | 3 tasks (0.5 vCPU, 1GB) 24/7 | ~$45 |
| **Application Load Balancer** | Standard ALB | ~$23 |
| **RDS PostgreSQL** | db.r6g.large Multi-AZ, 100GB | ~$380 |
| **ElastiCache Redis** | cache.r6g.large x 3 nodes | ~$510 |
| **NAT Gateway** | 3 NAT Gateways | ~$97 |
| **S3** | 100GB storage + requests | ~$10 |
| **CloudFront** | 1TB transfer | ~$85 |
| **Data Transfer** | Various | ~$50 |
| **CloudWatch** | Logs and metrics | ~$15 |
| **KMS** | 2 keys | ~$2 |
| **Total** | | **~$1,217/month** |

### Development Environment

Much cheaper with:
- Single NAT Gateway: Save ~$65/month
- Single-AZ RDS: Save ~$190/month
- Smaller instance types: Save ~$200/month
- Redis 2-node cluster: Save ~$170/month

**Dev Total:** ~$600/month

### Cost Optimization Tips

1. **Use Spot for non-production**: 70-90% savings on Fargate
2. **Reserved Instances**: Save 30-50% on RDS/ElastiCache
3. **Right-size resources**: Monitor and adjust instance types
4. **S3 Lifecycle policies**: Move old data to cheaper tiers
5. **CloudFront**: Reduces data transfer costs
6. **Auto Scaling**: Scale down during off-hours

## Deployment Steps

### Initial Deployment

```bash
# 1. Initialize
terraform init

# 2. Validate
terraform validate

# 3. Format
terraform fmt -recursive

# 4. Plan
terraform plan -out=tfplan

# 5. Apply
terraform apply tfplan
```

### Update Deployment

```bash
# Update container image
terraform plan \
  -var="container_image=123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v2.0.0" \
  -out=tfplan

terraform apply tfplan
```

### Blue-Green Deployment

```bash
# 1. Deploy new version to staging
terraform workspace select staging
terraform apply

# 2. Test staging
./scripts/test-staging.sh

# 3. Switch production
terraform workspace select production
terraform apply
```

## Monitoring

### CloudWatch Dashboards

Access dashboards at: https://console.aws.amazon.com/cloudwatch/

- **Application Dashboard**: ECS metrics, ALB requests, error rates
- **Database Dashboard**: RDS performance, connections, queries
- **Cache Dashboard**: Redis hits/misses, memory usage

### Alarms

The following alarms are configured:

1. **High CPU** (ECS tasks > 80%)
2. **High Memory** (ECS tasks > 80%)
3. **High Error Rate** (ALB 5xx > 5%)
4. **Database CPU** (RDS > 80%)
5. **Database Connections** (> 80% of max)
6. **Redis Memory** (> 90%)
7. **ALB Unhealthy Targets** (> 0)

### Logs

```bash
# View ECS logs
aws logs tail /aws/ecs/myapp-production --follow

# View ALB logs (in S3)
aws s3 ls s3://myapp-production-alb-logs/alb/ --recursive

# Query logs with CloudWatch Insights
aws logs start-query \
  --log-group-name /aws/ecs/myapp-production \
  --start-time $(date -u -d '1 hour ago' +%s) \
  --end-time $(date -u +%s) \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/'
```

## Security Best Practices

### Implemented

✅ **Encryption at rest** for RDS, ElastiCache, S3
✅ **Encryption in transit** with TLS/SSL everywhere
✅ **KMS** for key management with rotation
✅ **IAM roles** with least privilege
✅ **Security groups** with minimal ports
✅ **VPC endpoints** to avoid internet traffic
✅ **Private subnets** for application and database tiers
✅ **WAF** integration ready (add WAF rules as needed)
✅ **CloudTrail** for audit logging
✅ **VPC Flow Logs** for network monitoring
✅ **Secrets Manager** integration ready
✅ **Multi-AZ** for high availability

### Recommended Additions

- AWS Shield Advanced for DDoS protection ($3,000/month)
- AWS WAF managed rules (~$50/month)
- GuardDuty for threat detection (~$50/month)
- AWS Config for compliance (~$20/month)
- Security Hub for centralized security (~$10/month)

## Disaster Recovery

### Backup Strategy

- **RDS**: Automated backups (30 days retention)
- **S3**: Versioning enabled
- **Infrastructure**: Terraform state in S3 with versioning

### Recovery Procedures

**Database Recovery:**
```bash
# List available snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier myapp-production-db

# Restore from snapshot
terraform import aws_db_instance.main <new-instance-id>
```

**Complete Stack Recovery:**
```bash
# Re-deploy from Terraform state
terraform init
terraform plan
terraform apply
```

**RTO/RPO:**
- RTO (Recovery Time Objective): 1-2 hours
- RPO (Recovery Point Objective): < 5 minutes

## Troubleshooting

### Common Issues

**1. ECS tasks not starting**
```bash
# Check task definition
aws ecs describe-task-definition --task-definition myapp-production

# Check service events
aws ecs describe-services \
  --cluster myapp-production \
  --services myapp-production

# Check logs
aws logs tail /aws/ecs/myapp-production --follow
```

**2. Database connection issues**
```bash
# Test from ECS task
aws ecs execute-command \
  --cluster myapp-production \
  --task <task-id> \
  --container app \
  --interactive \
  --command "psql -h <rds-endpoint> -U dbadmin -d appdb"
```

**3. High costs**
```bash
# Check Cost Explorer
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

## Cleanup

### Destroy Resources

```bash
# Disable deletion protection first
terraform apply -var="environment=development"

# Destroy everything
terraform destroy

# Verify nothing remains
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=myapp
```

**Note:** This will delete:
- All ECS services and tasks
- Load balancers
- RDS databases (final snapshot taken if production)
- ElastiCache clusters
- S3 buckets (if empty)
- CloudFront distributions
- All associated resources

## Advanced Topics

### Multi-Region Deployment

Deploy to multiple regions for global availability:

```bash
# Deploy to us-east-1
terraform workspace new us-east-1
terraform apply

# Deploy to eu-west-1
terraform workspace new eu-west-1
terraform apply -var="aws_region=eu-west-1"
```

### CI/CD Integration

```yaml
# .github/workflows/terraform.yml
name: Terraform
on:
  push:
    branches: [main]
jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform init
      - run: terraform plan
      - run: terraform apply -auto-approve
```

## Support

For issues or questions:
- Check AWS CloudWatch logs
- Review Terraform state: `terraform show`
- Validate configuration: `terraform validate`
- Check AWS Service Health Dashboard

## License

Internal use only - proprietary.
