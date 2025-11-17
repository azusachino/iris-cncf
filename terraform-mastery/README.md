# Terraform Mastery: Multi-Cloud Infrastructure as Code

Comprehensive guide to mastering Terraform across AWS, Azure, and GCP.

## 🎯 Learning Objectives

- Master Terraform fundamentals (state, modules, workspaces)
- Deploy infrastructure across AWS, Azure, and GCP
- Build reusable, composable modules
- Implement multi-cloud architectures
- Advanced patterns (remote state, dynamic blocks, for_each)
- CI/CD integration and automation
- Testing and validation strategies

## 📚 Repository Structure

```
terraform-mastery/
├── basics/              # Terraform fundamentals
│   ├── syntax/         # HCL syntax and features
│   ├── state/          # State management
│   ├── modules/        # Module basics
│   └── workspaces/     # Workspace management
│
├── aws/                # AWS-specific examples
│   ├── vpc/           # VPC and networking
│   ├── compute/       # EC2, ASG, Lambda
│   ├── containers/    # ECS, EKS
│   ├── databases/     # RDS, DynamoDB
│   └── complete-app/  # Full application stack
│
├── azure/              # Azure-specific examples
│   ├── vnet/          # Virtual networks
│   ├── compute/       # VMs, VMSS
│   ├── aks/           # Azure Kubernetes Service
│   ├── databases/     # Azure SQL, Cosmos DB
│   └── complete-app/  # Full application stack
│
├── gcp/                # GCP-specific examples
│   ├── vpc/           # VPC and networking
│   ├── compute/       # Compute Engine, GKE
│   ├── gke/           # Google Kubernetes Engine
│   ├── databases/     # Cloud SQL, Firestore
│   └── complete-app/  # Full application stack
│
├── multi-cloud/        # Multi-cloud patterns
│   ├── abstraction/   # Cloud-agnostic modules
│   ├── disaster-recovery/ # Cross-cloud DR
│   └── global-app/    # Global distributed app
│
├── modules/            # Reusable modules library
│   ├── compute/       # Compute modules
│   ├── networking/    # Network modules
│   ├── database/      # Database modules
│   └── monitoring/    # Observability modules
│
└── advanced/           # Advanced topics
    ├── testing/       # Terratest examples
    ├── ci-cd/         # Pipeline integration
    ├── security/      # Security scanning
    └── patterns/      # Design patterns
```

## 🚀 Quick Start

### Installation

```bash
# Install Terraform
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installation
terraform version
```

### Basic Workflow

```bash
# Initialize Terraform (download providers)
terraform init

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

## 📖 Learning Path

### Week 1: Terraform Fundamentals
- HCL syntax and data types
- Resources, data sources, variables
- Outputs and locals
- State management
- Provider configuration

### Week 2: AWS with Terraform
- VPC and networking
- EC2 and Auto Scaling
- Load balancers and Route 53
- RDS and DynamoDB
- S3 and CloudFront
- Complete application deployment

### Week 3: Azure with Terraform
- Virtual Networks and NSGs
- Virtual Machines and Scale Sets
- Azure Kubernetes Service
- Azure SQL and Cosmos DB
- Complete application deployment

### Week 4: GCP with Terraform
- VPC and firewall rules
- Compute Engine and Managed Instance Groups
- Google Kubernetes Engine
- Cloud SQL and Firestore
- Complete application deployment

### Week 5: Modules and Best Practices
- Creating reusable modules
- Module composition
- Module registry
- Versioning and testing
- Documentation

### Week 6: Advanced Patterns
- Remote state with locking
- Workspaces for environments
- Dynamic blocks and for_each
- Conditional resources
- Import existing infrastructure

### Week 7: Multi-Cloud Architecture
- Cloud-agnostic abstractions
- Cross-cloud networking
- Multi-cloud Kubernetes
- Disaster recovery patterns

### Week 8: Production & CI/CD
- Terraform Cloud / Enterprise
- GitOps with Terraform
- Automated testing (Terratest)
- Security scanning (tfsec, checkov)
- Pipeline integration

## 💡 Key Concepts

### 1. State Management

**Local State:**
```hcl
# terraform.tfstate in local directory
# Simple but not suitable for teams
```

**Remote State (Recommended):**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

**Alternative Backends:**
- **Azure**: azurerm (Storage Account)
- **GCP**: gcs (Cloud Storage)
- **Terraform Cloud**: remote
- **HashiCorp Consul**: consul

### 2. Variables and Outputs

**Variables:**
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}
```

**Outputs:**
```hcl
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

### 3. Modules

**Module Structure:**
```
module/
├── main.tf       # Resources
├── variables.tf  # Input variables
├── outputs.tf    # Output values
├── versions.tf   # Provider versions
└── README.md     # Documentation
```

**Using Modules:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
```

### 4. Data Sources

```hcl
# Query existing resources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

### 5. Advanced Features

**For Each:**
```hcl
resource "aws_instance" "server" {
  for_each = toset(["web", "api", "worker"])

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "server-${each.key}"
  }
}
```

**Dynamic Blocks:**
```hcl
resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Application security group"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

**Conditional Resources:**
```hcl
resource "aws_instance" "web" {
  count = var.create_instance ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
}
```

## 🏗️ Multi-Cloud Patterns

### Pattern 1: Cloud-Agnostic Modules

```hcl
# modules/compute/main.tf
module "aws_compute" {
  count  = var.cloud_provider == "aws" ? 1 : 0
  source = "./aws"
  # ...
}

module "azure_compute" {
  count  = var.cloud_provider == "azure" ? 1 : 0
  source = "./azure"
  # ...
}

module "gcp_compute" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  source = "./gcp"
  # ...
}
```

### Pattern 2: Multi-Cloud Deployment

```hcl
# Deploy same app to multiple clouds
provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = "my-project"
  region  = "us-central1"
}

module "aws_app" {
  source = "./modules/app"
  providers = {
    aws = aws
  }
}

module "azure_app" {
  source = "./modules/app"
  providers = {
    azurerm = azurerm
  }
}
```

### Pattern 3: Cross-Cloud Networking

```hcl
# VPN between AWS and Azure
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "azurerm_virtual_network_gateway" "main" {
  name                = "azure-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  # ...
}

resource "aws_vpn_connection" "azure" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
}
```

## 🔒 Security Best Practices

1. **Never commit secrets**
   - Use environment variables
   - Use secret management services (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)
   - Use Terraform Cloud for encrypted variables

2. **Use remote state with encryption**
   - Enable encryption at rest
   - Use state locking (DynamoDB for S3, lease for Consul)

3. **Scan for security issues**
   ```bash
   # tfsec
   tfsec .

   # checkov
   checkov -d .

   # terrascan
   terrascan scan
   ```

4. **Principle of least privilege**
   - IAM roles for Terraform
   - Separate credentials per environment

5. **Enable audit logging**
   - CloudTrail (AWS)
   - Activity Log (Azure)
   - Cloud Audit Logs (GCP)

## 🧪 Testing

### Terraform Validate
```bash
terraform validate
```

### Terraform Plan
```bash
terraform plan -out=tfplan
```

### Terratest (Go-based testing)
```go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestTerraformVPC(t *testing.T) {
    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../examples/vpc",
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    vpcID := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcID)
}
```

## 📊 Terraform Cloud / Enterprise

Benefits:
- Remote state management
- Collaborative runs
- Policy as Code (Sentinel)
- Private module registry
- Cost estimation
- VCS integration

## 🎓 Certification Preparation

### HashiCorp Certified: Terraform Associate

Topics covered:
1. Understand infrastructure as code (IaC) concepts
2. Understand Terraform's purpose
3. Understand Terraform basics
4. Use the Terraform CLI
5. Interact with Terraform modules
6. Navigate Terraform workflow
7. Implement and maintain state
8. Read, generate, and modify configuration
9. Understand Terraform Cloud and Enterprise

## 📝 Best Practices Checklist

- [ ] Use version control (Git)
- [ ] Remote state with locking
- [ ] Separate environments (dev, staging, prod)
- [ ] Use modules for reusability
- [ ] Pin provider versions
- [ ] Use variables for flexibility
- [ ] Document with README and comments
- [ ] Use consistent naming conventions
- [ ] Tag resources for cost tracking
- [ ] Use workspaces or separate directories per environment
- [ ] Run `terraform fmt` and `terraform validate`
- [ ] Use `.gitignore` for sensitive files
- [ ] Implement security scanning
- [ ] Use data sources instead of hardcoding
- [ ] Leverage locals for computed values

## 🔗 Resources

- **Official Docs**: https://www.terraform.io/docs
- **Registry**: https://registry.terraform.io/
- **Best Practices**: https://www.terraform-best-practices.com/
- **AWS Modules**: https://github.com/terraform-aws-modules
- **Azure Modules**: https://github.com/Azure/terraform-azurerm-modules
- **GCP Modules**: https://github.com/terraform-google-modules

Start with basics, progress through single-cloud examples, then tackle multi-cloud architectures!
