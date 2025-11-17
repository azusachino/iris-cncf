# Cross-Cloud Service Mapping: AWS, Azure, GCP

Complete service equivalency guide for multi-cloud architectures.

## 1. Compute Services

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **Virtual Machines** | EC2 | Virtual Machines | Compute Engine | All support custom machine types |
| **VM Auto Scaling** | Auto Scaling Groups | VM Scale Sets | Managed Instance Groups | Similar features across all |
| **Serverless Functions** | Lambda | Azure Functions | Cloud Functions | AWS: 15 min limit, Azure: unlimited (Premium), GCP: 9 min |
| **Container Registry** | ECR | Azure Container Registry | Artifact Registry / GCR | GCP migrating from GCR to Artifact Registry |
| **Managed Kubernetes** | EKS | AKS | GKE | GCP has most mature K8s (Google created it) |
| **Container Orchestration** | ECS | Azure Container Instances | Cloud Run | ECS is AWS-specific, Cloud Run is serverless |
| **Serverless Containers** | Fargate | Azure Container Instances | Cloud Run | Cloud Run auto-scales to zero |
| **Batch Processing** | AWS Batch | Azure Batch | Cloud Batch (Preview) | AWS Batch most mature |
| **Virtual Desktop** | WorkSpaces | Azure Virtual Desktop | - | Azure has best VDI solution |
| **ARM-based VMs** | Graviton (t4g, m6g, c6g) | Ampere Altra | Tau T2A | AWS has most ARM options |

### Compute Sizing Comparison

**AWS Instance Types:**
- **t3.medium**: 2 vCPU, 4 GB RAM - Burstable
- **m5.xlarge**: 4 vCPU, 16 GB RAM - General purpose
- **c5.2xlarge**: 8 vCPU, 16 GB RAM - Compute optimized
- **r5.2xlarge**: 8 vCPU, 64 GB RAM - Memory optimized

**Azure VM Sizes:**
- **B2s**: 2 vCPU, 4 GB RAM - Burstable (≈ t3.medium)
- **D4s_v5**: 4 vCPU, 16 GB RAM - General purpose (≈ m5.xlarge)
- **F8s_v2**: 8 vCPU, 16 GB RAM - Compute optimized (≈ c5.2xlarge)
- **E8s_v5**: 8 vCPU, 64 GB RAM - Memory optimized (≈ r5.2xlarge)

**GCP Machine Types:**
- **e2-medium**: 2 vCPU, 4 GB RAM - Burstable (≈ t3.medium)
- **n2-standard-4**: 4 vCPU, 16 GB RAM - General purpose (≈ m5.xlarge)
- **c2-standard-8**: 8 vCPU, 32 GB RAM - Compute optimized
- **m2-ultramem-208**: Up to 12 TB RAM - Largest memory options

### Pricing Models

| Model | AWS | Azure | GCP |
|-------|-----|-------|-----|
| **On-Demand** | Standard pricing | Standard pricing | Standard pricing |
| **Reserved / Committed** | Reserved Instances (1/3 year) | Reserved Instances (1/3 year) | Committed Use Discounts (1/3 year) |
| **Savings Plans** | Compute & EC2 Savings Plans | - | Flexible Committed Use |
| **Spot / Preemptible** | Spot Instances | Spot VMs | Preemptible / Spot VMs |
| **Sustained Use** | - | - | Automatic sustained use discounts |

## 2. Storage Services

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **Object Storage** | S3 | Blob Storage | Cloud Storage | S3 is most feature-rich |
| **Block Storage** | EBS | Managed Disks | Persistent Disk | Similar performance tiers |
| **File Storage (NFS)** | EFS | Azure Files (NFS) | Filestore | EFS is most elastic |
| **File Storage (SMB)** | FSx for Windows | Azure Files (SMB) | - | Azure best for Windows |
| **Archive Storage** | S3 Glacier | Archive Blob Storage | Coldline/Archive Storage | AWS has Deep Archive tier |
| **Data Transfer** | DataSync, Transfer Family | Azure File Sync | Transfer Service | - |
| **Hybrid Storage** | Storage Gateway | StorSimple (deprecated) | - | AWS strongest in hybrid |

### Object Storage Tiers

**AWS S3:**
- **S3 Standard**: Frequent access, 99.99% availability
- **S3 Intelligent-Tiering**: Auto-move between tiers
- **S3 Standard-IA**: Infrequent access, lower cost
- **S3 One Zone-IA**: Single AZ, even lower cost
- **S3 Glacier Instant**: Millisecond retrieval
- **S3 Glacier Flexible**: Minutes to hours retrieval
- **S3 Glacier Deep Archive**: 12-48 hours retrieval, lowest cost

**Azure Blob Storage:**
- **Hot**: Frequent access
- **Cool**: Infrequent access (30+ days)
- **Archive**: Rare access (180+ days), hours retrieval

**GCP Cloud Storage:**
- **Standard**: Frequent access
- **Nearline**: Infrequent access (30+ days)
- **Coldline**: Rarely accessed (90+ days)
- **Archive**: Long-term archive (365+ days)

### Block Storage Performance

**AWS EBS:**
- **gp3**: General purpose SSD, 3,000-16,000 IOPS
- **io2**: Provisioned IOPS SSD, up to 64,000 IOPS
- **st1**: Throughput optimized HDD, 500 IOPS
- **sc1**: Cold HDD, 250 IOPS

**Azure Managed Disks:**
- **Premium SSD**: Up to 20,000 IOPS
- **Standard SSD**: Up to 6,000 IOPS
- **Standard HDD**: Up to 2,000 IOPS
- **Ultra Disk**: Up to 160,000 IOPS

**GCP Persistent Disk:**
- **SSD**: Up to 100,000 IOPS
- **Balanced**: Up to 80,000 IOPS
- **Standard**: Up to 15,000 IOPS
- **Extreme**: Up to 120,000 IOPS

## 3. Networking Services

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **Virtual Network** | VPC | Virtual Network (VNet) | VPC | Similar concepts |
| **Load Balancer (L7)** | ALB | Application Gateway | Cloud Load Balancing (HTTP/S) | GCP has global LB by default |
| **Load Balancer (L4)** | NLB | Load Balancer | Cloud Load Balancing (TCP/UDP) | NLB has static IPs |
| **CDN** | CloudFront | Azure CDN / Front Door | Cloud CDN | CloudFront most edge locations |
| **DNS** | Route 53 | Azure DNS / Traffic Manager | Cloud DNS | Route 53 most routing policies |
| **VPN** | Site-to-Site VPN | VPN Gateway | Cloud VPN | Similar features |
| **Dedicated Connection** | Direct Connect | ExpressRoute | Cloud Interconnect | All require partner/carrier |
| **Network Hub** | Transit Gateway | Virtual WAN | - | AWS has dedicated service |
| **Private Connectivity** | PrivateLink | Private Link | Private Service Connect | AWS pioneered this |
| **DDoS Protection** | Shield | DDoS Protection | Cloud Armor | Shield Advanced is premium |
| **Web Application Firewall** | WAF | WAF | Cloud Armor | Similar rule capabilities |
| **Global Accelerator** | Global Accelerator | Front Door | Cloud Load Balancing | GCP LB is global by default |

### VPC / VNet Comparison

**AWS VPC:**
- CIDR blocks: /16 to /28
- Secondary CIDR blocks supported
- Subnets: One AZ only
- Route tables: Per subnet association
- **Unique**: VPC Endpoints for AWS services

**Azure VNet:**
- Address space: /8 to /29
- Multiple address spaces supported
- Subnets: VNet-wide (not AZ-specific)
- Route tables: Per subnet association
- **Unique**: Service Endpoints for Azure services

**GCP VPC:**
- Subnet mode: Auto or custom
- Subnets: Regional (multi-zone by default)
- Global VPC: Single VPC across all regions
- Routes: VPC-wide
- **Unique**: Global VPC, shared VPC

### Load Balancer Feature Comparison

| Feature | AWS ALB | Azure Application Gateway | GCP HTTP(S) LB |
|---------|---------|--------------------------|----------------|
| **Scope** | Regional | Regional | Global |
| **Path routing** | Yes | Yes | Yes |
| **Host routing** | Yes | Yes | Yes |
| **WebSocket** | Yes | Yes | Yes |
| **HTTP/2** | Yes | Yes | Yes |
| **WAF integration** | Yes | Yes | Yes (Cloud Armor) |
| **SSL offload** | Yes | Yes | Yes |
| **Autoscaling** | Automatic | Manual config | Automatic |
| **Static IP** | No | Yes | Yes (Anycast) |
| **Multi-region** | No | No | Yes |

## 4. Database Services

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **Managed SQL** | RDS | Azure SQL Database | Cloud SQL | RDS supports most engines |
| **PostgreSQL** | RDS for PostgreSQL, Aurora PostgreSQL | Azure Database for PostgreSQL | Cloud SQL for PostgreSQL, AlloyDB | AlloyDB is new high-perf option |
| **MySQL** | RDS for MySQL, Aurora MySQL | Azure Database for MySQL | Cloud SQL for MySQL | Aurora is AWS-optimized |
| **SQL Server** | RDS for SQL Server | Azure SQL Database | Cloud SQL for SQL Server | Azure has best SQL Server integration |
| **NoSQL Key-Value** | DynamoDB | Cosmos DB (Table API) | Cloud Bigtable | DynamoDB fully serverless |
| **NoSQL Document** | DocumentDB | Cosmos DB (MongoDB API) | Cloud Firestore | Cosmos DB multi-model |
| **In-Memory Cache** | ElastiCache | Azure Cache for Redis | Memorystore | Similar Redis/Memcached support |
| **Data Warehouse** | Redshift | Synapse Analytics | BigQuery | BigQuery is serverless |
| **Time Series** | Timestream | Time Series Insights | - | AWS newest offering |
| **Ledger** | QLDB | - | - | AWS-only blockchain database |
| **Graph** | Neptune | Cosmos DB (Gremlin API) | - | Neptune purpose-built |

### Database Scaling Comparison

**AWS Aurora:**
- Up to 128 TB storage
- Up to 15 read replicas
- Cross-region replicas
- Serverless v2 with auto-scaling
- **Unique**: Aurora Global Database

**Azure SQL Database:**
- Up to 4 TB (single database)
- Up to 100 TB (Hyperscale)
- Active geo-replication
- Serverless tier available
- **Unique**: Built-in intelligence

**GCP Cloud SQL:**
- Up to 64 TB storage
- Up to 10 read replicas
- Cross-region replicas
- No serverless option
- **Unique**: Automatic storage increase

**GCP AlloyDB:**
- Up to 64 TB storage
- 100x faster analytics than standard PostgreSQL
- Column-based engine for analytics
- **Unique**: Best for hybrid OLTP/OLAP

## 5. Security & Identity

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **Identity Management** | IAM | Azure Active Directory | Cloud Identity | Azure AD most comprehensive |
| **Single Sign-On** | AWS SSO (IAM Identity Center) | Azure AD SSO | Cloud Identity | Azure AD industry standard |
| **Managed Keys** | KMS | Key Vault | Cloud KMS | Similar encryption features |
| **Secrets Management** | Secrets Manager | Key Vault (Secrets) | Secret Manager | AWS & GCP separate from KMS |
| **HSM** | CloudHSM | Dedicated HSM | Cloud HSM | FIPS 140-2 Level 3 |
| **Certificate Management** | ACM | App Service Certificates | Certificate Manager | ACM is free for AWS resources |
| **DDoS Protection** | Shield | DDoS Protection | Cloud Armor | Shield Standard is free |
| **Web Application Firewall** | WAF | WAF | Cloud Armor | Similar managed rules |
| **Compliance** | Artifact | Compliance Manager | Compliance Reports Manager | AWS most certifications |
| **Threat Detection** | GuardDuty | Microsoft Defender | Security Command Center | Azure Defender most comprehensive |

### IAM Model Comparison

**AWS IAM:**
- Users, Groups, Roles, Policies
- Resource-based and identity-based policies
- JSON policy documents
- **Unique**: Service Control Policies (SCPs) in Organizations

**Azure AD / RBAC:**
- Users, Groups, Service Principals
- Role assignments (who, what, where)
- Built-in and custom roles
- **Unique**: Seamless integration with Office 365

**GCP IAM:**
- Members (users, groups, service accounts)
- Roles (primitive, predefined, custom)
- Policies bind members to roles
- **Unique**: Organization-level IAM conditions

## 6. Kubernetes Service Comparison

| Feature | EKS | AKS | GKE |
|---------|-----|-----|-----|
| **Control Plane** | $0.10/hour | Free | $0.10/hour (Autopilot free) |
| **K8s Version** | Usually 1-2 behind | Usually 1 behind | Latest (Google created K8s) |
| **Upgrade** | Manual or managed | Manual or auto | Manual or auto |
| **Node Pools** | Managed Node Groups | Node Pools | Node Pools |
| **Serverless** | Fargate | Azure Container Instances | Autopilot (recommended) |
| **Auto Scaling** | Cluster Autoscaler | Cluster Autoscaler | GKE Autoscaler (native) |
| **Workload Identity** | IRSA (IAM for SA) | AAD Pod Identity | Workload Identity |
| **Private Cluster** | Yes | Yes | Yes |
| **Windows Nodes** | Yes | Yes | Yes |
| **ARM Nodes** | Yes (Graviton) | Yes | Yes (Tau T2A) |
| **Service Mesh** | App Mesh | Istio add-on | Anthos Service Mesh |
| **GitOps** | Flux (community) | Flux (built-in) | Config Sync (Anthos) |

**Recommendation:**
- **EKS**: Deep AWS integration, enterprise multi-cloud strategy
- **AKS**: Azure ecosystem, Microsoft tooling (Azure DevOps)
- **GKE**: Best Kubernetes experience, Google Cloud Platform

## 7. Monitoring & Logging

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **Metrics** | CloudWatch | Azure Monitor Metrics | Cloud Monitoring | Similar capabilities |
| **Logs** | CloudWatch Logs | Azure Monitor Logs | Cloud Logging | Log Analytics (Azure) most powerful |
| **Distributed Tracing** | X-Ray | Application Insights | Cloud Trace | App Insights best APM |
| **Profiling** | X-Ray | Application Insights Profiler | Cloud Profiler | - |
| **Uptime Monitoring** | CloudWatch Synthetics | Application Insights | Cloud Monitoring Uptime | - |
| **SIEM** | Security Hub | Azure Sentinel | Chronicle | Sentinel is leading SIEM |
| **Cost Management** | Cost Explorer | Cost Management | Cost Management | Azure has best cost optimization tools |

## 8. Developer Tools & DevOps

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **CI/CD** | CodePipeline | Azure DevOps | Cloud Build | Azure DevOps most complete |
| **Source Control** | CodeCommit | Azure Repos | Cloud Source Repositories | Use GitHub/GitLab instead |
| **Build Service** | CodeBuild | Azure Pipelines | Cloud Build | Cloud Build has Kaniko integration |
| **Artifact Repository** | CodeArtifact | Azure Artifacts | Artifact Registry | Artifact Registry supports most formats |
| **Infrastructure as Code** | CloudFormation | ARM Templates / Bicep | Deployment Manager | Use Terraform for multi-cloud |
| **API Management** | API Gateway | API Management | Apigee / API Gateway | Apigee enterprise-grade |
| **Message Queue** | SQS | Storage Queues / Service Bus | Pub/Sub | SQS fully managed, Pub/Sub most features |
| **Event Bus** | EventBridge | Event Grid | Eventarc | EventBridge most integrations |
| **Workflow** | Step Functions | Logic Apps | Workflows | Similar state machine capabilities |

## 9. Machine Learning & AI

| Service Category | AWS | Azure | GCP | Notes |
|-----------------|-----|-------|-----|-------|
| **ML Platform** | SageMaker | Azure ML | Vertex AI | SageMaker most comprehensive |
| **Notebooks** | SageMaker Notebooks | Azure ML Notebooks | Vertex AI Workbench | Similar Jupyter-based |
| **AutoML** | SageMaker Autopilot | Azure AutoML | Vertex AI AutoML | GCP pioneered AutoML |
| **Vision API** | Rekognition | Computer Vision | Vision AI | Similar capabilities |
| **Speech API** | Transcribe, Polly | Speech Services | Speech-to-Text, Text-to-Speech | Azure has best speech recognition |
| **NLP API** | Comprehend | Text Analytics | Natural Language AI | - |
| **Translation** | Translate | Translator | Translation AI | GCP supports most languages |
| **ML Infrastructure** | EC2 P4/P5 | NC-series VMs | A2 VMs (A100 GPUs) | AWS has latest instances |

## 10. Migration Strategies

### Lift-and-Shift (Rehost)

**AWS:**
- AWS Application Migration Service (CloudEndure)
- VM Import/Export
- Database Migration Service

**Azure:**
- Azure Migrate
- Azure Site Recovery
- Database Migration Service

**GCP:**
- Migrate for Compute Engine
- Migrate for Anthos
- Database Migration Service

### Refactor

**AWS:**
- Elastic Beanstalk (PaaS)
- App Runner (containers)
- Lambda (serverless)

**Azure:**
- App Service (PaaS)
- Container Apps
- Azure Functions

**GCP:**
- App Engine (PaaS)
- Cloud Run (containers)
- Cloud Functions

### Cost Comparison Rule of Thumb

Generally speaking:
- **Compute**: AWS and GCP are similar, Azure slightly higher
- **Storage**: GCP often cheapest, AWS and Azure similar
- **Network**: GCP egress expensive, Azure has cheaper options
- **Databases**: Pricing varies widely by service
- **Always**: Use cost calculators and consider discounts (Reserved/Committed)

## 11. Multi-Cloud Architecture Patterns

### Active-Active Multi-Cloud
```
Global Load Balancer (e.g., NS1, Cloudflare)
            |
    +-------+-------+
    |               |
  AWS             Azure
  EKS              AKS
    |               |
Shared Database (cross-cloud replication)
```

### Cloud-Specific Workloads
```
User Request
    |
+---+---+
|       |
AWS     GCP
(Web)   (ML/Analytics)
  |       |
  +---+---+
      |
  Shared Data Store
```

### Hybrid Cloud Pattern
```
On-Premises
    |
ExpressRoute / Direct Connect / Interconnect
    |
Primary Cloud (Azure / AWS / GCP)
    |
Cross-Cloud VPN/Interconnect
    |
Secondary Cloud (DR / Specific Workloads)
```

## Key Takeaways for Multi-Cloud Mastery

1. **Compute**: All clouds have similar IaaS offerings, GCP has best K8s, Azure best Windows
2. **Storage**: S3 is most feature-rich, but all have equivalent tiers
3. **Networking**: GCP has simplest with global VPC, AWS most flexible, Azure middle ground
4. **Databases**: AWS most options, Azure best SQL Server, GCP best analytics (BigQuery)
5. **Kubernetes**: GKE most advanced, EKS best AWS integration, AKS catching up fast
6. **Serverless**: Lambda most mature, Cloud Run most elegant, Azure Functions .NET-first
7. **Pricing**: Compare based on actual workload, use reserved/committed for savings
8. **Strategy**: Choose based on strengths (AWS breadth, Azure Windows, GCP data/K8s)
