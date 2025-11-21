# Variables for Complete AWS Application Stack

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Application Configuration
variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8080
}

variable "app_count" {
  description = "Number of application instances"
  type        = number
  default     = 3
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units"
  type        = number
  default     = 512
}

variable "fargate_memory" {
  description = "Fargate instance memory in MB"
  type        = number
  default     = 1024
}

variable "container_image" {
  description = "Docker image for the application"
  type        = string
}

# Database Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

# Redis Configuration
variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_auth_token" {
  description = "Redis authentication token"
  type        = string
  sensitive   = true
}

# Auto Scaling Configuration
variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 2
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 20
}

variable "autoscaling_target_cpu" {
  description = "Target CPU utilization for auto scaling"
  type        = number
  default     = 70
}

variable "autoscaling_target_memory" {
  description = "Target memory utilization for auto scaling"
  type        = number
  default     = 80
}

# Monitoring Configuration
variable "alert_email" {
  description = "Email address for CloudWatch alerts"
  type        = string
}

variable "enable_container_insights" {
  description = "Enable ECS Container Insights"
  type        = bool
  default     = true
}

# Tags
variable "additional_tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
