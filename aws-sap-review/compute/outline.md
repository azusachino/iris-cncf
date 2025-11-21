# AWS Compute Services - Detailed Outline

## 1. Amazon EC2 (Elastic Compute Cloud)

### Instance Types and Families
- **General Purpose** (T3, T4g, M5, M6i)
  - Balanced compute, memory, networking
  - T-series: Burstable performance with CPU credits
  - Use case: Web servers, small databases, dev environments

- **Compute Optimized** (C5, C6i, C6g)
  - High-performance processors
  - Use case: Batch processing, media transcoding, HPC, gaming servers

- **Memory Optimized** (R5, R6i, X2, z1d)
  - Large memory footprint
  - Use case: In-memory databases, real-time big data analytics

- **Storage Optimized** (I3, I4i, D2, H1)
  - High IOPS and throughput
  - Use case: NoSQL databases, data warehouses, distributed file systems

- **Accelerated Computing** (P4, G5, Inf1, F1)
  - GPU or FPGA hardware accelerators
  - Use case: Machine learning, graphics workloads, genomics

### Purchasing Options

#### On-Demand Instances
- Pay per hour/second
- No upfront cost or long-term commitment
- **Use case**: Short-term, spiky, or unpredictable workloads

#### Reserved Instances (RI)
- **Standard RI**: Up to 72% discount, cannot change instance family
- **Convertible RI**: Up to 54% discount, can change instance family
- 1-year or 3-year terms
- Payment options: All upfront, partial upfront, no upfront
- **Use case**: Steady-state, predictable workloads

#### Savings Plans
- **Compute Savings Plans**: Up to 66% discount, flexible across instance family, size, AZ, region, OS
- **EC2 Instance Savings Plans**: Up to 72% discount, committed to instance family in a region
- **Use case**: More flexibility than RIs with similar savings

#### Spot Instances
- Up to 90% discount
- Can be terminated by AWS with 2-minute warning
- **Use case**: Fault-tolerant, flexible workloads (batch, big data, CI/CD)
- **Spot Fleet**: Mix of Spot and On-Demand instances
- **Spot Block**: 1-6 hour uninterrupted Spot instances (being phased out)

#### Dedicated Hosts
- Physical server dedicated for your use
- **Use case**: Compliance requirements, server-bound software licenses
- Most expensive option

#### Dedicated Instances
- Instances on hardware dedicated to you
- May share hardware with other instances from same account
- Less expensive than Dedicated Hosts

### Placement Groups

#### Cluster Placement Group
- Instances placed close together in single AZ
- Low latency, high network throughput (10 Gbps+)
- **Use case**: HPC applications, big data jobs requiring low latency

#### Spread Placement Group
- Instances placed on distinct underlying hardware
- Max 7 instances per AZ per group
- **Use case**: Critical applications requiring high availability

#### Partition Placement Group
- Instances divided into partitions (different racks)
- Each partition has its own network and power source
- **Use case**: Distributed databases (Hadoop, Cassandra, Kafka)

### Auto Scaling

#### Auto Scaling Components
- **Launch Template/Configuration**: AMI, instance type, security groups, user data
- **Auto Scaling Group**: Min, max, desired capacity
- **Scaling Policies**: When and how to scale

#### Scaling Policies
- **Target Tracking**: Maintain metric at target (e.g., CPU at 50%)
- **Step Scaling**: Scale based on CloudWatch alarm thresholds
- **Simple Scaling**: Legacy, single scaling adjustment
- **Scheduled Scaling**: Scale at specific times
- **Predictive Scaling**: ML-based prediction of future capacity needs

#### Scaling Strategies
- **Scale out early, scale in slowly**: Gradual cooldown periods
- **Multiple metrics**: CPU, memory, network, custom metrics
- **Warm pools**: Pre-initialized instances for faster scaling

### EC2 Advanced Features

#### Hibernate
- Save RAM state to EBS volume
- Resume faster than stop/start
- Max 60 days hibernation
- **Use case**: Long-running processes, pre-warmed caches

#### Elastic Fabric Adapter (EFA)
- Network device for HPC and ML applications
- OS-bypass for low latency
- **Use case**: MPI workloads, ML training

#### Elastic Network Adapter (ENA)
- Enhanced networking up to 100 Gbps
- Lower latency, higher PPS (packets per second)

#### EC2 Instance Connect
- Browser-based SSH connection
- No need for key pair management
- IAM-controlled access

## 2. AWS Lambda

### Core Concepts
- Serverless compute service
- Pay per request and compute time
- Automatic scaling
- Supports multiple runtimes (Python, Node.js, Java, Go, .NET, Ruby)
- Custom runtimes with Runtime API

### Configuration

#### Memory and CPU
- Memory: 128 MB to 10,240 MB (10 GB)
- CPU allocated proportionally to memory
- 1,769 MB memory = 1 vCPU

#### Timeout
- Default: 3 seconds
- Max: 15 minutes (900 seconds)

#### Environment Variables
- Max 4 KB total size
- Can be encrypted with KMS

#### Ephemeral Storage (/tmp)
- 512 MB to 10,240 MB (10 GB)
- Temporary storage per execution

### Execution Model

#### Cold Start vs Warm Start
- **Cold start**: New execution environment initialization (100ms - 1s+)
- **Warm start**: Reuse existing environment (1-2ms)
- **Mitigation**: Provisioned Concurrency (pre-warmed instances)

#### Concurrency
- **Account limit**: 1,000 concurrent executions per region (can be increased)
- **Reserved concurrency**: Guarantee capacity for critical functions
- **Provisioned concurrency**: Pre-initialized execution environments

### Invocation Types

#### Synchronous
- Wait for response
- API Gateway, ALB, Cognito, CloudFront (Lambda@Edge)

#### Asynchronous
- Lambda queues request and returns immediately
- 2 automatic retries on failure
- Dead Letter Queue (DLQ) for failed events
- S3, SNS, EventBridge, CloudWatch Events

#### Event Source Mapping
- Lambda polls the event source
- Kinesis, DynamoDB Streams, SQS
- Batch processing with configurable batch size

### Lambda Layers
- Share code and dependencies across functions
- Max 5 layers per function
- Max 250 MB total size (unzipped)
- **Use case**: Common libraries, custom runtimes, monitoring tools

### Lambda@Edge
- Run Lambda at CloudFront edge locations
- Modify requests/responses at edge
- **Use case**: A/B testing, SEO optimization, bot detection
- **Limitations**: Max 128 MB memory, max 30s timeout

### Cost Optimization
- Right-size memory allocation (test different sizes)
- Use ARM-based Graviton2 processors (20% better price/performance)
- Optimize cold starts (minimize dependencies)
- Use Step Functions for long-running workflows

### Security
- IAM execution role (what Lambda can access)
- Resource-based policy (who can invoke Lambda)
- VPC integration (access private resources)
- Environment variable encryption with KMS

## 3. Amazon ECS (Elastic Container Service)

### Launch Types

#### EC2 Launch Type
- You manage EC2 instances
- More control over infrastructure
- Can use Spot/Reserved/Savings Plans
- **Use case**: Need specific instance types, large workloads, cost optimization

#### Fargate Launch Type
- Serverless, AWS manages infrastructure
- No EC2 instances to manage
- Pay per task (vCPU and memory)
- **Use case**: Reduce operational overhead, variable workloads

### Core Concepts

#### Task Definition
- JSON definition of container(s)
- Image, CPU, memory, port mappings
- IAM role, networking mode
- Immutable, versioned

#### Service
- Maintains desired count of tasks
- Integrated with ELB for load balancing
- Auto Scaling support
- Rolling updates and deployments

#### Cluster
- Logical grouping of tasks/services
- Can mix EC2 and Fargate launch types

### Networking Modes

#### awsvpc (Recommended)
- Each task gets its own ENI
- Full VPC networking features
- Required for Fargate

#### bridge
- Default Docker bridge network
- Port mapping required
- Tasks share host's network namespace

#### host
- Task uses host's network
- No port mapping
- **Use case**: High performance networking

### Auto Scaling
- **Target Tracking**: Scale based on CloudWatch metrics
- **Step Scaling**: Scale based on CloudWatch alarms
- **Scheduled Scaling**: Scale at specific times
- **Cluster Auto Scaling (CAS)**: Scale EC2 capacity providers

### Load Balancing
- **ALB**: HTTP/HTTPS, path-based routing, dynamic port mapping
- **NLB**: TCP/UDP, high performance, static IP
- **CLB**: Legacy, not recommended for new deployments

## 4. Amazon EKS (Elastic Kubernetes Service)

### Control Plane
- Managed by AWS
- Multi-AZ for high availability
- Automatic version upgrades available
- Integrated with AWS services (IAM, VPC, ALB, EBS)

### Worker Nodes

#### Managed Node Groups
- AWS manages lifecycle (AMI, patching)
- Auto Scaling support
- Can use Spot instances

#### Self-Managed Nodes
- You manage EC2 instances
- More control and customization
- Use eksctl or CloudFormation

#### Fargate Pods
- Serverless, no nodes to manage
- Pay per pod
- **Use case**: Batch jobs, CI/CD, microservices

### Networking

#### VPC CNI Plugin
- Each pod gets VPC IP address
- Direct VPC routing
- Can exhaust IP addresses in large clusters
- **Solution**: Secondary CIDR blocks, custom networking

#### Security Groups for Pods
- Assign security groups to individual pods
- Finer-grained network security

### Authentication and Authorization

#### IAM Roles for Service Accounts (IRSA)
- Map Kubernetes ServiceAccount to IAM role
- Fine-grained permissions per pod
- Uses OIDC provider

#### AWS IAM Authenticator
- kubectl authentication via IAM

### Storage

#### EBS CSI Driver
- Dynamic provisioning of EBS volumes
- Supports snapshots and volume expansion

#### EFS CSI Driver
- Shared file system across pods
- ReadWriteMany access mode

#### FSx for Lustre CSI Driver
- High-performance file system
- **Use case**: HPC, ML training

### Cost Optimization
- Fargate for variable workloads
- Spot instances for fault-tolerant workloads
- Cluster Autoscaler or Karpenter for node scaling
- Right-size pod requests and limits

## 5. AWS Batch

### Core Concepts
- Fully managed batch processing
- Automatically provisions compute resources
- Integrates with Spot instances
- No cost (pay for underlying resources)

### Components

#### Job Definition
- How to run job (Docker image, vCPUs, memory)
- IAM role, environment variables
- Similar to ECS task definition

#### Job Queue
- Jobs wait here before execution
- Priority-based scheduling
- Connected to compute environments

#### Compute Environment
- Managed or Unmanaged
- EC2 or Fargate
- Spot or On-Demand
- Min, max, desired vCPUs

### Use Cases
- Financial modeling and risk analysis
- Media transcoding
- Genomics analysis
- Log analysis and ETL

### Best Practices
- Use Spot instances (up to 90% cost savings)
- Set appropriate retry strategies
- Use array jobs for large-scale parallel processing
- Monitor with CloudWatch metrics

## 6. Elastic Load Balancing (ELB)

### Application Load Balancer (ALB)
- Layer 7 (HTTP/HTTPS)
- Path-based and host-based routing
- WebSocket and HTTP/2 support
- Listener rules with conditions
- Target types: EC2, IP, Lambda
- **Use case**: Microservices, containers, Lambda

### Network Load Balancer (NLB)
- Layer 4 (TCP/UDP/TLS)
- Ultra-low latency, high throughput
- Static IP addresses
- PrivateLink support
- **Use case**: Extreme performance, static IP, non-HTTP protocols

### Gateway Load Balancer (GWLB)
- Layer 3 (IP packets)
- Deploy, scale, manage 3rd-party virtual appliances
- **Use case**: Firewalls, IDS/IPS, deep packet inspection

### Classic Load Balancer (CLB)
- Legacy (Layer 4/7)
- Not recommended for new applications
- Limited features compared to ALB/NLB

### Cross-Zone Load Balancing
- Distribute traffic evenly across all targets in all AZs
- **ALB**: Always enabled, no charge
- **NLB**: Disabled by default, charges for cross-AZ data transfer
- **CLB**: Disabled by default, no charge when enabled

### Connection Draining / Deregistration Delay
- Complete in-flight requests before deregistering target
- Default: 300 seconds
- Range: 0-3600 seconds

## 7. Design Patterns

### High Availability Pattern
```
Internet -> Route 53
    -> Multi-region ALB
        -> Auto Scaling Group (Multi-AZ)
            -> EC2 instances in private subnets
```

### Batch Processing Pattern
```
S3 Event -> Lambda -> Submit AWS Batch Job
    -> Batch Compute Environment (Spot instances)
        -> Process data -> Store results in S3
```

### Serverless Web Application
```
CloudFront -> S3 (static) + API Gateway -> Lambda -> DynamoDB
```

### Microservices on ECS/EKS
```
ALB -> Target Group
    -> ECS Service (Fargate)
        -> Multiple containers (app, sidecar)
            -> Connect to RDS, ElastiCache, etc.
```

## 8. Cost Optimization Strategies

### EC2 Cost Optimization
1. **Right-sizing**: Use Compute Optimizer recommendations
2. **Savings Plans**: Commit to consistent usage (66-72% savings)
3. **Spot Instances**: Fault-tolerant workloads (90% savings)
4. **Auto Scaling**: Scale based on demand
5. **Instance Scheduler**: Stop instances outside business hours

### Lambda Cost Optimization
1. **Optimize memory**: Balance performance vs cost
2. **ARM (Graviton2)**: 20% better price-performance
3. **Reduce cold starts**: Minimize package size
4. **Use asynchronous**: Avoid waiting for responses

### Container Cost Optimization
1. **Fargate Spot**: Up to 70% discount
2. **EKS with Spot**: Mixed node groups
3. **Right-size containers**: Set appropriate CPU/memory
4. **Horizontal Pod Autoscaling**: Scale based on metrics

## 9. Security Best Practices

### EC2 Security
- Use IMDSv2 (Instance Metadata Service V2)
- Encrypted EBS volumes
- Systems Manager Session Manager (no SSH keys)
- Security groups as stateful firewalls
- NACLs for subnet-level security

### Lambda Security
- Least privilege IAM roles
- VPC integration for private resource access
- Encrypt environment variables with KMS
- Use Secrets Manager for sensitive data

### Container Security
- Scan images for vulnerabilities (ECR image scanning)
- Use minimal base images
- Non-root containers
- Read-only root filesystem
- Secrets management (Secrets Manager, Parameter Store)

## 10. Monitoring and Troubleshooting

### CloudWatch Metrics
- **EC2**: CPU, Network, Disk (detailed monitoring for 1-min intervals)
- **Lambda**: Invocations, Errors, Duration, Throttles
- **ECS/EKS**: CPU, Memory utilization per task/pod

### CloudWatch Logs
- Lambda logs automatic
- EC2 needs CloudWatch agent
- ECS/EKS with awslogs or Fluent Bit

### X-Ray
- Distributed tracing
- Identify performance bottlenecks
- Service map visualization

### Common Issues
- **EC2**: Instance status checks, Auto Scaling not scaling
- **Lambda**: Timeout, out of memory, cold starts, throttling
- **ECS**: Task failing health checks, insufficient resources
- **EKS**: Pod pending (resource constraints), image pull errors
