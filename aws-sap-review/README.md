# AWS Solutions Architect Professional (SAP) Review

Complete review guide for AWS SAP certification covering all exam domains.

## 📋 Exam Domains & Weightings

1. **Design for Organizational Complexity** (26%)
   - Cross-account AWS architectures
   - Multi-account strategies (AWS Organizations)
   - Hybrid and multi-region architectures

2. **Design for New Solutions** (29%)
   - Business requirements to AWS architecture
   - Reliable, secure, and resilient architectures
   - Cost-optimized designs

3. **Continuous Improvement for Existing Solutions** (25%)
   - Improving solutions for operational excellence
   - Security improvements
   - Performance and cost optimization

4. **Accelerate Workload Migration and Modernization** (20%)
   - Migration strategies (6 R's)
   - Cloud-native modernization
   - Data migration and database modernization

## 🎯 Study Strategy

### Phase 1: Foundation Review (Week 1)
- Compute (EC2, Lambda, Containers)
- Storage (S3, EBS, EFS)
- Networking (VPC, Direct Connect, Transit Gateway)

### Phase 2: Advanced Services (Week 2)
- Database (RDS, DynamoDB, Aurora)
- Security (IAM, KMS, Security Hub)
- Migration & Disaster Recovery

### Phase 3: Design Patterns (Week 3)
- Multi-account architectures
- Hybrid connectivity patterns
- High availability and disaster recovery patterns

## 📚 Directory Structure

```
aws-sap-review/
├── compute/              # EC2, Lambda, ECS, EKS, Batch
├── storage/              # S3, EBS, EFS, FSx, Storage Gateway
├── database/             # RDS, DynamoDB, Aurora, Redshift
├── networking/           # VPC, Direct Connect, Route 53
├── security/             # IAM, KMS, Secrets Manager, WAF
├── migration/            # Migration Hub, DMS, Snow Family
├── cost-optimization/    # Cost Explorer, Budgets, Trusted Advisor
├── disaster-recovery/    # Backup strategies, pilot light, warm standby
└── design-patterns/      # Well-Architected patterns
```

## 🔑 Key Focus Areas

### Multi-Account Architecture
- AWS Organizations and SCPs
- AWS Control Tower
- Consolidated billing and cost allocation
- Cross-account access patterns

### Hybrid Connectivity
- Direct Connect vs VPN
- Transit Gateway architecture
- AWS PrivateLink
- VPC peering vs Transit Gateway

### Security in Depth
- IAM policies and permission boundaries
- AWS KMS encryption patterns
- AWS Secrets Manager vs Parameter Store
- AWS WAF and Shield Advanced

### High Availability Patterns
- Multi-AZ deployments
- Multi-region active-active/active-passive
- Auto Scaling patterns
- Route 53 health checks and failover

### Cost Optimization
- Reserved Instances vs Savings Plans
- Spot Instances strategies
- S3 storage classes and lifecycle policies
- Right-sizing recommendations

## 📖 Learning Resources

Each subdirectory contains:
- **outline.md**: Detailed topic breakdown
- **examples/**: Code samples and configurations
- **scenarios/**: Real-world design scenarios
- **cheatsheet.md**: Quick reference

## 🧪 Practice Scenarios

Common scenario types to master:
1. Design multi-account structure for a large enterprise
2. Implement disaster recovery for mission-critical applications
3. Optimize costs for a high-traffic web application
4. Design secure hybrid connectivity for on-premises integration
5. Migrate legacy applications to AWS with minimal downtime

## 💡 Pro Tips

- Focus on **why** you choose a service, not just **what** the service does
- Understand trade-offs between different solutions
- Master multi-account and hybrid scenarios (heavily tested)
- Know all connectivity options (Direct Connect, VPN, PrivateLink, Transit Gateway)
- Understand cost implications of architectural decisions

## 📝 Quick Reference

### Compute Decision Tree
- **Predictable, long-running**: EC2 Reserved Instances
- **Variable, fault-tolerant**: EC2 Spot Instances
- **Short-lived, event-driven**: Lambda
- **Containerized, managed**: ECS Fargate or EKS Fargate
- **Batch processing**: AWS Batch

### Storage Decision Tree
- **Object storage**: S3
- **Block storage**: EBS
- **Shared file system**: EFS (Linux) or FSx (Windows/Lustre)
- **Hybrid storage**: Storage Gateway
- **Backup**: AWS Backup

### Database Decision Tree
- **Relational, managed**: RDS or Aurora
- **NoSQL, key-value**: DynamoDB
- **Data warehouse**: Redshift
- **In-memory cache**: ElastiCache
- **Graph database**: Neptune

## 🎓 Next Steps

1. Review each domain subdirectory
2. Work through scenarios in each section
3. Practice designing solutions for given requirements
4. Take practice exams
5. Review weak areas

Start with the domain where you feel least confident!
