# AWS Networking - Detailed Outline

## 1. Amazon VPC (Virtual Private Cloud)

### VPC Components
- **CIDR Block**: IPv4 (10.0.0.0/16) and IPv6
- **Subnets**: Public (route to IGW) vs Private
- **Route Tables**: Define traffic routing
- **Internet Gateway (IGW)**: Internet access for public subnets
- **NAT Gateway/Instance**: Outbound internet for private subnets
- **VPC Endpoints**: Private AWS service access

### Subnet Design
- **Public Subnet**: Route to IGW, hosts NAT Gateway, ALB, Bastion
- **Private Subnet**: No direct internet, hosts app servers, databases
- **Reserved IPs**: AWS reserves 5 IPs per subnet (.0, .1, .2, .3, .255)
- **Multi-AZ**: Spread subnets across AZs for high availability

### Security

#### Security Groups (Stateful)
- Instance-level firewall
- Allow rules only (implicitly deny all)
- Stateful: Return traffic automatically allowed
- Can reference other security groups
- **Best practice**: Least privilege, specific rules

#### Network ACLs (Stateless)
- Subnet-level firewall
- Allow and deny rules
- Stateless: Must explicitly allow return traffic
- Rules evaluated in order (lowest number first)
- **Use case**: Additional layer of defense, block specific IPs

### VPC Peering
- Connect two VPCs privately
- Non-transitive (A<->B, B<->C doesn't mean A<->C)
- No overlapping CIDR blocks
- Cross-account and cross-region supported
- **Limitations**: Max 125 peering connections per VPC
- **Use case**: Connect VPCs within same organization

## 2. Hybrid Connectivity

### AWS VPN (Site-to-Site VPN)

#### Components
- **Virtual Private Gateway (VGW)**: VPN concentrator on AWS side
- **Customer Gateway (CGW)**: Customer's VPN device
- **VPN Connection**: Two IPSec tunnels for redundancy

#### Characteristics
- Internet-based encrypted tunnels
- Up to 1.25 Gbps per tunnel
- Supports static and dynamic (BGP) routing
- **Cost**: Low (VPN connection charge + data transfer)
- **Latency**: Variable (internet-dependent)
- **Use case**: Quick setup, low bandwidth, cost-sensitive

#### Accelerated VPN
- VPN with AWS Global Accelerator
- Improved performance using AWS global network
- **Use case**: Better latency and throughput over VPN

### AWS Direct Connect

#### Characteristics
- Dedicated network connection to AWS
- Consistent network performance
- Speeds: 50 Mbps - 100 Gbps
- Private connection (not over internet)
- **Cost**: Port hours + data transfer out
- **Setup time**: Weeks to months

#### Virtual Interfaces (VIF)
- **Private VIF**: Access VPC resources
- **Public VIF**: Access public AWS services (S3, DynamoDB)
- **Transit VIF**: Connect to Transit Gateway

#### Direct Connect Gateway
- Connect Direct Connect to multiple VPCs across regions
- Max 10 VPCs per Direct Connect Gateway
- **Use case**: Multi-region VPC access from on-premises

#### Redundancy Patterns
- **High Availability**: Two Direct Connect connections at different locations
- **Backup**: VPN as backup for Direct Connect
- **Maximum Resilience**: Multiple connections + separate customer routers + VPN backup

### AWS Transit Gateway

#### Key Features
- Hub-and-spoke network topology
- Connect VPCs, VPN, Direct Connect, SD-WAN
- Supports transitive routing (A<->B<->C means A<->C)
- **Scalability**: Up to 5,000 attachments
- **Throughput**: Up to 50 Gbps per attachment (can increase)

#### Routing
- Route tables per attachment
- Blackhole routes for blocking traffic
- Route propagation from VPN/Direct Connect

#### Multi-Region
- Transit Gateway Peering across regions
- Inter-region traffic routed over AWS backbone
- **Use case**: Global network architecture

#### Use Cases
- Replace complex VPC peering mesh
- Centralized egress/ingress VPC
- Centralized security inspection (firewall)
- Simplified network management

### AWS PrivateLink

#### Characteristics
- Private connectivity to services
- No internet, VPN, NAT, peering required
- Traffic stays within AWS network
- Supports NLB or Gateway Load Balancer

#### Use Cases
- SaaS provider exposing service to customers
- Shared services VPC pattern
- Private access to AWS services (VPC endpoints)

#### VPC Endpoints
- **Interface Endpoint**: ENI with private IP, powered by PrivateLink
- **Gateway Endpoint**: Route table entry (S3, DynamoDB only)
- **Use case**: Private access without internet gateway

## 3. Amazon Route 53

### Routing Policies

#### Simple Routing
- Single resource or multiple IPs (random selection)
- No health checks
- **Use case**: Single web server

#### Weighted Routing
- Split traffic by percentage (A: 70%, B: 30%)
- Health checks supported
- **Use case**: A/B testing, gradual migration

#### Latency-Based Routing
- Route to lowest latency region
- Health checks supported
- **Use case**: Global application, best user experience

#### Failover Routing
- Active-passive setup
- Primary and secondary resources
- Health checks required
- **Use case**: Disaster recovery

#### Geolocation Routing
- Route based on user's geographic location
- Can specify default location
- **Use case**: Content localization, compliance

#### Geoproximity Routing
- Route based on proximity with bias adjustment
- **Use case**: Shift traffic to specific regions

#### Multi-Value Answer Routing
- Return multiple IPs (up to 8)
- Health checks per record
- **Use case**: Simple load distribution with health checks

### Traffic Flow
- Visual editor for complex routing policies
- Version control for routing configurations
- **Use case**: Complex routing with multiple policies

### Health Checks
- Monitor endpoint availability
- HTTP, HTTPS, TCP
- Can check CloudWatch alarms
- String matching for response validation
- **Calculated health checks**: Combine multiple checks with AND/OR

### Resolver
- DNS resolution for hybrid environments
- **Inbound endpoints**: On-premises to AWS
- **Outbound endpoints**: AWS to on-premises
- **Use case**: Seamless DNS across hybrid architecture

## 4. Amazon CloudFront

### Core Concepts
- Global CDN with 400+ edge locations
- Caches content close to users
- Reduces latency and offloads origin
- Supports HTTP/HTTPS, RTMP (deprecated)

### Origins
- **S3**: Static content, Origin Access Identity (OAI)
- **Custom Origin**: ALB, EC2, on-premises
- **Origin Groups**: Failover between origins

### Cache Behavior
- Path patterns to route to different origins
- TTL (Time To Live) settings
- Query string and cookie forwarding
- Header-based caching

### Security
- **Signed URLs/Cookies**: Restrict access to content
- **Origin Access Identity**: S3 bucket only accessible via CloudFront
- **Field-Level Encryption**: Encrypt sensitive data
- **AWS WAF Integration**: DDoS protection, geo-blocking
- **AWS Shield Standard**: Automatic DDoS protection (free)
- **AWS Shield Advanced**: Enhanced DDoS protection ($3k/month)

### Lambda@Edge
- Run Lambda functions at edge locations
- Viewer request/response, origin request/response
- **Use case**: URL rewrite, A/B testing, authentication

### Regional Edge Caches
- Between edge locations and origin
- Larger cache for less popular content
- Automatic, no configuration needed

## 5. AWS Global Accelerator

### Characteristics
- Two static anycast IPs
- Routes traffic over AWS global network
- Automatic failover between regions
- Health checks and traffic dials

### vs CloudFront
- **Global Accelerator**: TCP/UDP, non-cacheable, consistent IPs
- **CloudFront**: HTTP/HTTPS, cacheable content, variable IPs

### Use Cases
- Gaming (UDP traffic)
- IoT (MQTT)
- VoIP
- HTTP for non-cacheable dynamic content
- Applications requiring static IPs

## 6. Elastic Load Balancing (ELB)

### Application Load Balancer (ALB)
- **Layer**: 7 (HTTP/HTTPS)
- **Routing**: Path, host, query string, headers, HTTP method
- **Targets**: EC2, IP, Lambda, containers
- **Features**: WebSocket, HTTP/2, redirects, fixed response
- **Security**: SSL/TLS termination, SNI (multiple certificates)
- **Use case**: Microservices, containerized applications

### Network Load Balancer (NLB)
- **Layer**: 4 (TCP/UDP/TLS)
- **Performance**: Millions requests/sec, ultra-low latency
- **Static IP**: One per AZ, Elastic IP support
- **Preserve IP**: Client IP visible to target
- **Use case**: Extreme performance, static IP, PrivateLink

### Gateway Load Balancer (GWLB)
- **Layer**: 3 (IP packets)
- **Protocol**: GENEVE on port 6081
- **Use case**: Firewalls, IDS/IPS, DPI appliances
- **Integration**: With VPC ingress routing

### Cross-Zone Load Balancing
- **ALB**: Always enabled (no charge)
- **NLB**: Optional (cross-AZ data transfer charges)
- **Use case**: Even distribution across AZs

### SSL/TLS
- **Certificate**: ACM (AWS Certificate Manager) or IAM
- **SNI**: Multiple domains on single ALB/NLB
- **SSL Policy**: Security policy for cipher suites

## 7. Network Design Patterns

### Hub-and-Spoke with Transit Gateway
```
                Transit Gateway
                      |
    +-----------------+-----------------+
    |                 |                 |
VPC-A            VPC-B            VPC-C
(Shared Services) (Production)   (Development)
```

### Centralized Egress
```
VPC-A, VPC-B, VPC-C -> Transit Gateway -> Egress VPC -> NAT Gateway -> Internet
```

### Centralized Security Inspection
```
Internet -> Ingress VPC (Firewall) -> Transit Gateway -> Workload VPCs
```

### Multi-Region with Global Accelerator
```
Users -> Global Accelerator (2 anycast IPs)
            |
    +-------+-------+
    |               |
us-east-1      eu-west-1
(Primary)      (Secondary)
```

### Hybrid Cloud Connectivity
```
On-Premises
    |
Direct Connect / VPN
    |
Direct Connect Gateway / Transit Gateway
    |
VPCs (Multiple Regions)
```

## 8. Cost Optimization

### Data Transfer Costs
- **Inbound**: Free
- **Outbound to Internet**: Charged (tiered pricing)
- **Cross-AZ**: Charged (except ALB)
- **Cross-Region**: Charged
- **VPC Peering**: Cross-AZ and cross-region charges
- **Transit Gateway**: Per attachment + data transfer

### Optimization Strategies
1. Use CloudFront for content delivery (reduces data transfer)
2. VPC endpoints for S3/DynamoDB (free, no internet gateway)
3. Keep traffic within same AZ when possible
4. Use Direct Connect for large data transfers
5. Aggregate network connections with Transit Gateway

## 9. Security Best Practices

### Defense in Depth
1. **Network ACLs**: Subnet-level filtering
2. **Security Groups**: Instance-level filtering
3. **WAF**: Application-level filtering
4. **Shield**: DDoS protection
5. **GuardDuty**: Threat detection

### Private Access
- VPC endpoints for AWS services
- PrivateLink for third-party services
- Private subnets for databases and internal services
- Bastion hosts or Systems Manager Session Manager for access

### Encryption
- TLS/SSL for data in transit
- VPN/Direct Connect with MACsec for hybrid
- PrivateLink keeps traffic within AWS network

## 10. Monitoring and Troubleshooting

### VPC Flow Logs
- Capture IP traffic information
- Publish to CloudWatch Logs or S3
- **Levels**: VPC, Subnet, ENI
- **Format**: srcaddr, dstaddr, srcport, dstport, protocol, action (ACCEPT/REJECT)
- **Use case**: Security analysis, troubleshooting

### CloudWatch Metrics
- **VPN**: TunnelState, TunnelDataIn/Out
- **Direct Connect**: ConnectionState, ConnectionBpsEgress/Ingress
- **Transit Gateway**: BytesIn/Out, PacketsIn/Out, PacketDropCount
- **NAT Gateway**: ActiveConnectionCount, BytesIn/Out
- **ELB**: RequestCount, TargetResponseTime, HealthyHostCount

### Reachability Analyzer
- Analyze network paths between source and destination
- Identifies configuration issues blocking traffic
- No packet sent (dry run analysis)

### Network Access Analyzer
- Identify unintended network access
- Specify network access requirements
- Validate compliance

### Common Issues
- **Cannot reach internet**: Check route table, IGW, NAT Gateway, security groups
- **Cannot reach between VPCs**: Check peering, Transit Gateway, route tables
- **High latency**: Check Direct Connect vs VPN, CloudFront, Global Accelerator
- **VPN tunnel down**: Check customer gateway configuration, BGP routes
- **Connection timeout**: Check security groups, NACLs, route tables
