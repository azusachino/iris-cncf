# Real-World Example: Managing Application Secrets with Vault and Terraform

This directory contains a complete, production-grade example of managing application secrets using HashiCorp Vault and Terraform.

## 🎯 Scenario

An application running in Kubernetes on EKS needs to access two types of secrets:
1.  **Static Secrets**: An API key and a service URL that rarely change.
2.  **Dynamic Secrets**: Short-lived credentials for a PostgreSQL database on RDS.

This example demonstrates a secure and automated solution to this common problem.

## ✨ Key Patterns and Technologies

*   **HashiCorp Vault**: Used as the central secrets management system.
    *   **KV v2 Engine**: For versioned, static secrets.
    *   **Database Secrets Engine**: For generating dynamic, just-in-time database credentials.
*   **Terraform**: For provisioning all infrastructure and Vault configuration as code.
*   **AWS EKS**: The Kubernetes platform for hosting the application.
*   **AWS RDS**: The managed PostgreSQL database.
*   **Vault Agent Sidecar Injection**: The recommended pattern for applications in Kubernetes to get secrets. The agent authenticates with Vault, retrieves secrets, and makes them available to the application on a shared memory volume.

## ⚙️ How It Works

1.  **Terraform Provisioning**:
    *   `terraform apply` will create the VPC, EKS cluster, and RDS database.
    *   It will then configure Vault by:
        *   Creating a KV v2 secrets engine at `secret/`.
        *   Creating a database secrets engine at `database/`.
        *   Storing a static secret at `secret/app/config`.
        *   Configuring the database engine to connect to the RDS instance.
        *   Creating a role that can generate read-only credentials for the database.
        *   Creating a Vault policy (`app-policy`) that grants permission to read the static secret and request dynamic database credentials.
        *   Configuring Kubernetes authentication and creating a role (`my-app`) that links a Kubernetes Service Account to the Vault policy.

2.  **Application Deployment**:
    *   When the Kubernetes deployment (`my-app`) is created, the Vault Agent Injector (which is assumed to be running in the cluster) mutates the pod specification.
    *   It adds a `vault-agent` sidecar container to the pod.
    *   This agent authenticates with Vault using the pod's Kubernetes Service Account token.
    *   The agent uses the templates defined in the pod's annotations to retrieve the static and dynamic secrets.
    *   It writes the secrets to a shared memory volume at `/vault/secrets`.

3.  **Application Runtime**:
    *   The application container sources the secret files from `/vault/secrets` to set environment variables.
    *   The application can then use these environment variables to get the API key, service URL, and database credentials.
    *   The Vault Agent automatically keeps the dynamic database credentials renewed and rotates them before they expire.

## 🚀 How to Use This Example

### Prerequisites

*   **Terraform CLI**: Installed and configured.
*   **Vault Server**: A running Vault server. The address and a token with sufficient permissions must be provided as variables.
*   **AWS Credentials**: Configured for Terraform to use.
*   **kubectl**: Installed and configured to connect to your Kubernetes cluster.
*   **Vault Agent Injector**: You must have the Vault Helm chart installed in your EKS cluster with the agent injector enabled.

### Steps

1.  **Clone the repository**:
    ```sh
    git clone <repository-url>
    cd terraform-mastery/real-world/vault-secrets
    ```

2.  **Configure Variables**:
    *   Create a `terraform.tfvars` file or set environment variables for the required variables in `variables.tf` (e.g., `TF_VAR_vault_addr`, `TF_VAR_vault_token`, `TF_VAR_db_username`, `TF_VAR_db_password`).

3.  **Initialize Terraform**:
    ```sh
    terraform init
    ```

4.  **Deploy the Infrastructure**:
    ```sh
    terraform apply
    ```

5.  **Verify**:
    *   Once applied, you can check the created resources in your AWS account and Vault server.
    *   You can deploy a sample application with the specified annotations to see the secret injection in action.
