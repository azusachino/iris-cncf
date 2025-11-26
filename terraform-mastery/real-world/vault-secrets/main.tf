# Real-World Example: Managing Application Secrets with Vault and Terraform
#
# This configuration demonstrates a secure, production-grade pattern for managing
# application secrets using HashiCorp Vault and Terraform.
#
# Pattern:
# 1. Infrastructure: An EKS cluster hosts a "real-world" backend application.
# 2. Vault for Static Secrets: An "app-secrets" Vault instance stores static
#    secrets (e.g., API keys, credentials) as key/value pairs. The application
#    is granted read-only access via a carefully scoped policy.
# 3. Vault for Dynamic Secrets: A "database" Vault instance generates dynamic, 
#    just-in-time credentials for an RDS PostgreSQL database. This eliminates
#    long-lived database credentials, significantly improving security.
# 4. Kubernetes Integration: The application pod is injected with a Vault Agent
#    sidecar, which authenticates with Vault, retrieves secrets, and writes them
#    to a shared memory volume. The application reads secrets from this volume
#    without ever touching the Vault API directly.
# 5. Terraform Automation: The entire infrastructure—EKS, RDS, and Vault
#    configuration—is provisioned and managed with Terraform.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # Secure backend for production state management
  backend "s3" {
    bucket         = "my-real-world-tf-state"
    key            = "real-world/vault-secrets/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}

provider "kubernetes" {
  config_path = "~/.kube/config" # Assumes kubeconfig is set up
}

# ========================================
# 1. Foundational Infrastructure (VPC & EKS)
# ========================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "vault-secrets-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # Use false for production multi-AZ
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "vault-secrets-cluster"
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    app_nodes = {
      instance_types = ["t3.medium"]
      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}

# ========================================
# 2. RDS PostgreSQL Database
# ========================================

resource "aws_db_instance" "app_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro"
  name                 = "myappdb"
  username             = var.db_username
  password             = var.db_password # Initial bootstrap password
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  publicly_accessible  = false # For production security

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "Allow EKS nodes to connect to RDS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = module.vpc.private_subnets
}

# ========================================
# 3. Vault Configuration
# ========================================

# --- Static Secrets (KV V2) ---
resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  options     = { version = "2" }
  description = "Stores static secrets for applications."
}

resource "vault_kv_secret_v2" "app_secret" {
  mount = vault_mount.kv.path
  name  = "app/config"
  data_json = jsonencode({
    "api_key"      = "STATIC-API-KEY-12345"
    "service_url"  = "https://api.example.com"
  })
}

# --- Dynamic Secrets (Database) ---
resource "vault_mount" "db" {
  path        = "database"
  type        = "database"
  description = "Generates dynamic credentials for PostgreSQL."
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend = vault_mount.db.path
  name    = "postgresql"

  allowed_roles = ["app-readonly"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${aws_db_instance.app_db.address}:${aws_db_instance.app_db.port}/${aws_db_instance.app_db.name}?sslmode=disable"
    username       = var.db_username
    password       = var.db_password
  }
}

resource "vault_database_secret_backend_role" "readonly_role" {
  backend = vault_mount.db.path
  name    = "app-readonly"
  db_name = vault_database_secret_backend_connection.postgres.name

  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";"
  ]

  default_ttl = "1h"
  max_ttl     = "24h"
}

# --- Vault Policy for the Application ---
resource "vault_policy" "app_policy" {
  name = "app-policy"

  policy = <<-
EOT
    # Read static secrets
    path "secret/data/app/config" {
      capabilities = ["read"]
    }

    # Request dynamic DB credentials
    path "database/creds/app-readonly" {
      capabilities = ["read"]
    }
  EOT
}

# --- Kubernetes Authentication ---
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "vault_auth_backend_role" "app_role" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "my-app"
  bound_service_account_names      = ["my-app-sa"]
  bound_service_account_namespaces = ["default"]
  token_policies                   = [vault_policy.app_policy.name]
  ttl                              = 3600 # 1 hour
}

# ========================================
# 4. Kubernetes Application Deployment
# ========================================

resource "kubernetes_service_account" "app" {
  metadata {
    name      = "my-app-sa"
    namespace = "default"
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name      = "my-app"
    namespace = "default"
    labels = {
      app = "my-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "my-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "my-app"
        }
        annotations = {
          # --- Vault Agent Injection ---
          "vault.hashicorp.com/agent-inject"                  = "true"
          "vault.hashicorp.com/role"                          = "my-app"
          "vault.hashicorp.com/agent-run-as-user"             = "100" # Run as non-root

          # --- Template for Static Secret ---
          "vault.hashicorp.com/agent-inject-secret-config"    = "secret/data/app/config"
          "vault.hashicorp.com/agent-inject-template-config"  = <<-
EOT
            {{- with secret "secret/data/app/config" -}}
            export API_KEY="{{ .Data.data.api_key }}"
            export SERVICE_URL="{{ .Data.data.service_url }}"
            {{- end }}
          EOT

          # --- Template for Dynamic Secret ---
          "vault.hashicorp.com/agent-inject-secret-db-creds"  = "database/creds/app-readonly"
          "vault.hashicorp.com/agent-inject-template-db-creds" = <<-
EOT
            {{- with secret "database/creds/app-readonly" -}}
            export DB_USERNAME="{{ .Data.username }}"
            export DB_PASSWORD="{{ .Data.password }}"
            {{- end }}
          EOT
        }
      }

      spec {
        service_account_name = kubernetes_service_account.app.metadata.0.name

        container {
          name  = "my-app"
          image = "my-app:1.0.0" # Replace with your application image
          ports {
            container_port = 8080
          }
          # Command to source the secrets and start the application
          command = ["/bin/sh", "-c"]
          args    = ["source /vault/secrets/config && source /vault/secrets/db-creds && /app/start"]

          # The /vault/secrets directory is a shared memory volume
          # populated by the Vault Agent sidecar.
          volume_mounts {
            name       = "vault-secrets"
            mount_path = "/vault/secrets"
            read_only  = true
          }
        }

        # The shared volume for secrets
        volume {
          name = "vault-secrets"
          empty_dir {
            medium = "Memory"
          }
        }
      }
    }
  }
}

# ========================================
# Outputs
# ========================================

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint."
  value       = module.eks.cluster_endpoint
}

output "database_address" {
  description = "PostgreSQL RDS instance address."
  value       = aws_db_instance.app_db.address
}

output "vault_policy_name" {
  description = "Name of the Vault policy created for the application."
  value       = vault_policy.app_policy.name
}

output "kubernetes_deployment_name" {
  description = "Name of the Kubernetes deployment."
  value       = kubernetes_deployment.app.metadata.0.name
}
