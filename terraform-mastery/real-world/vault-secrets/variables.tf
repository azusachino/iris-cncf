# Terraform Variables for Vault Secrets Example

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "vault_addr" {
  description = "The address of the Vault server."
  type        = string
  sensitive   = true
}

variable "vault_token" {
  description = "The Vault token to use for authentication."
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "The initial bootstrap username for the RDS database."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The initial bootstrap password for the RDS database."
  type        = string
  sensitive   = true
}
