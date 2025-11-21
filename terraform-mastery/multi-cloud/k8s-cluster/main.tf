# Multi-Cloud Kubernetes Cluster Deployment
# Demonstrates deploying Kubernetes clusters across AWS, Azure, and GCP
# with a unified interface and consistent configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Remote state configuration (recommended for production)
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "multi-cloud/k8s/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = "MultiCloudK8s"
      Environment = var.environment
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# GCP Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Local variables for common configuration
locals {
  cluster_name = "${var.environment}-k8s"

  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "MultiCloudK8s"
  }

  # Kubernetes version across clouds (use compatible versions)
  k8s_version = "1.28"
}

# ========================================
# AWS EKS Cluster
# ========================================

module "eks" {
  count  = var.deploy_aws ? 1 : 0
  source = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "${local.cluster_name}-aws"
  cluster_version = local.k8s_version

  vpc_id     = module.vpc_aws[0].vpc_id
  subnet_ids = module.vpc_aws[0].private_subnets

  # Cluster endpoint access
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Cluster addons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Managed node groups
  eks_managed_node_groups = {
    general = {
      name = "general-ng"

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 2
      max_size     = 10
      desired_size = 3

      labels = {
        role = "general"
      }

      tags = {
        NodeGroup = "general"
      }
    }

    spot = {
      name = "spot-ng"

      instance_types = ["t3.medium", "t3a.medium"]
      capacity_type  = "SPOT"

      min_size     = 0
      max_size     = 5
      desired_size = 2

      labels = {
        role = "spot"
      }

      taints = [{
        key    = "spot"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
  }

  tags = local.common_tags
}

# AWS VPC for EKS
module "vpc_aws" {
  count   = var.deploy_aws ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false  # Multi-AZ NAT for production
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Kubernetes-specific tags
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.cluster_name}-aws" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.cluster_name}-aws" = "shared"
  }

  tags = local.common_tags
}

# ========================================
# Azure AKS Cluster
# ========================================

module "aks" {
  count  = var.deploy_azure ? 1 : 0
  source = "Azure/aks/azurerm"
  version = "~> 7.0"

  resource_group_name = azurerm_resource_group.aks[0].name
  location            = azurerm_resource_group.aks[0].location
  cluster_name        = "${local.cluster_name}-azure"
  prefix              = "aks"

  kubernetes_version        = local.k8s_version
  automatic_channel_upgrade = "stable"

  # Network configuration
  network_plugin    = "azure"
  network_policy    = "azure"
  vnet_subnet_id    = azurerm_subnet.aks[0].id

  # System node pool
  agents_size               = "Standard_D2s_v3"
  agents_min_count          = 2
  agents_max_count          = 10
  agents_count              = 3
  enable_auto_scaling       = true
  agents_availability_zones = ["1", "2", "3"]

  # Additional node pools
  node_pools = {
    user = {
      name                = "user"
      vm_size            = "Standard_D2s_v3"
      enable_auto_scaling = true
      min_count          = 1
      max_count          = 5
      node_count         = 2
      zones              = ["1", "2", "3"]

      labels = {
        role = "user"
      }
    }

    spot = {
      name                = "spot"
      vm_size            = "Standard_D2s_v3"
      enable_auto_scaling = true
      min_count          = 0
      max_count          = 3
      node_count         = 1
      priority           = "Spot"
      eviction_policy    = "Delete"
      spot_max_price     = -1  # Pay up to on-demand price

      labels = {
        role = "spot"
      }

      node_taints = [
        "spot=true:NoSchedule"
      ]
    }
  }

  # Enable Azure AD integration
  role_based_access_control_enabled = true
  rbac_aad                         = true
  rbac_aad_managed                 = true

  # Enable monitoring
  log_analytics_workspace_enabled = true

  tags = local.common_tags
}

resource "azurerm_resource_group" "aks" {
  count    = var.deploy_azure ? 1 : 0
  name     = "${local.cluster_name}-rg"
  location = var.azure_location
  tags     = local.common_tags
}

# Azure VNet for AKS
resource "azurerm_virtual_network" "aks" {
  count               = var.deploy_azure ? 1 : 0
  name                = "${local.cluster_name}-vnet"
  location            = azurerm_resource_group.aks[0].location
  resource_group_name = azurerm_resource_group.aks[0].name
  address_space       = ["10.1.0.0/16"]
  tags                = local.common_tags
}

resource "azurerm_subnet" "aks" {
  count                = var.deploy_azure ? 1 : 0
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.aks[0].name
  virtual_network_name = azurerm_virtual_network.aks[0].name
  address_prefixes     = ["10.1.0.0/20"]
}

# ========================================
# GCP GKE Cluster
# ========================================

module "gke" {
  count   = var.deploy_gcp ? 1 : 0
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 29.0"

  project_id = var.gcp_project_id
  name       = "${local.cluster_name}-gcp"
  region     = var.gcp_region

  kubernetes_version = local.k8s_version
  release_channel    = "STABLE"

  network           = google_compute_network.gke[0].name
  subnetwork        = google_compute_subnetwork.gke[0].name
  ip_range_pods     = "pods"
  ip_range_services = "services"

  # Enable private cluster
  enable_private_endpoint = false
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.0.0/28"

  # Master authorized networks (restrict access)
  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  ]

  # Enable Workload Identity
  identity_namespace = "${var.gcp_project_id}.svc.id.goog"

  # Enable addons
  horizontal_pod_autoscaling = true
  http_load_balancing        = true
  network_policy             = true
  gce_pd_csi_driver          = true

  # Node pools
  node_pools = [
    {
      name               = "general"
      machine_type       = "e2-medium"
      min_count          = 2
      max_count          = 10
      initial_node_count = 3
      disk_size_gb       = 50
      disk_type          = "pd-standard"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = false
    },
    {
      name               = "spot"
      machine_type       = "e2-medium"
      min_count          = 0
      max_count          = 5
      initial_node_count = 1
      disk_size_gb       = 50
      disk_type          = "pd-standard"
      auto_repair        = true
      auto_upgrade       = true
      preemptible        = true
    }
  ]

  node_pools_labels = {
    all = {}
    general = {
      role = "general"
    }
    spot = {
      role = "spot"
    }
  }

  node_pools_taints = {
    all = []
    general = []
    spot = [{
      key    = "spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }

  node_pools_tags = {
    all = ["gke-node"]
    general = []
    spot = []
  }
}

# GCP VPC for GKE
resource "google_compute_network" "gke" {
  count                   = var.deploy_gcp ? 1 : 0
  name                    = "${local.cluster_name}-network"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "gke" {
  count         = var.deploy_gcp ? 1 : 0
  name          = "${local.cluster_name}-subnet"
  ip_cidr_range = "10.2.0.0/20"
  region        = var.gcp_region
  network       = google_compute_network.gke[0].name
  project       = var.gcp_project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.2.16.0/20"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.32.0/20"
  }
}

# ========================================
# Outputs
# ========================================

output "eks_cluster_endpoint" {
  description = "AWS EKS cluster endpoint"
  value       = var.deploy_aws ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_name" {
  description = "AWS EKS cluster name"
  value       = var.deploy_aws ? module.eks[0].cluster_name : null
}

output "aks_cluster_name" {
  description = "Azure AKS cluster name"
  value       = var.deploy_azure ? module.aks[0].cluster_name : null
}

output "aks_kube_config_raw" {
  description = "Azure AKS kubeconfig"
  value       = var.deploy_azure ? module.aks[0].kube_config_raw : null
  sensitive   = true
}

output "gke_cluster_name" {
  description = "GCP GKE cluster name"
  value       = var.deploy_gcp ? module.gke[0].name : null
}

output "gke_cluster_endpoint" {
  description = "GCP GKE cluster endpoint"
  value       = var.deploy_gcp ? module.gke[0].endpoint : null
}

# Kubeconfig generation commands
output "eks_kubeconfig_command" {
  description = "Command to update kubeconfig for AWS EKS"
  value       = var.deploy_aws ? "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks[0].cluster_name}" : null
}

output "aks_kubeconfig_command" {
  description = "Command to update kubeconfig for Azure AKS"
  value       = var.deploy_azure ? "az aks get-credentials --resource-group ${azurerm_resource_group.aks[0].name} --name ${module.aks[0].cluster_name}" : null
}

output "gke_kubeconfig_command" {
  description = "Command to update kubeconfig for GCP GKE"
  value       = var.deploy_gcp ? "gcloud container clusters get-credentials ${module.gke[0].name} --region ${var.gcp_region} --project ${var.gcp_project_id}" : null
}
