# Multi-Cloud Kubernetes Variables

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ========================================
# Cloud Provider Selection
# ========================================

variable "deploy_aws" {
  description = "Deploy to AWS"
  type        = bool
  default     = true
}

variable "deploy_azure" {
  description = "Deploy to Azure"
  type        = bool
  default     = false
}

variable "deploy_gcp" {
  description = "Deploy to GCP"
  type        = bool
  default     = false
}

# ========================================
# AWS Variables
# ========================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# ========================================
# Azure Variables
# ========================================

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

# ========================================
# GCP Variables
# ========================================

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = ""
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}
