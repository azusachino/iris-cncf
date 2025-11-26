# CNCF Real-World Example: GitOps with ArgoCD

This directory contains a practical example of implementing a GitOps workflow using ArgoCD.

## 🎯 Scenario

You want to automate the deployment of a "guestbook" application to a Kubernetes cluster. The goal is to have a system where any changes to the application's Kubernetes manifests in a Git repository are automatically reflected in the cluster.

## ✨ Key Patterns and Technologies

*   **GitOps**: The practice of using a Git repository as the single source of truth for declarative infrastructure and applications.
*   **ArgoCD**: A declarative, GitOps continuous delivery tool for Kubernetes.
*   **Kubernetes**: The container orchestration platform.

## ⚙️ How It Works

1.  **ArgoCD Application**:
    *   The `application.yaml` file defines an ArgoCD `Application` resource. This resource tells ArgoCD:
        *   Which Git repository to monitor (`repoURL`).
        *   Which path within the repository to look for manifests (`path`).
        *   Which branch or tag to track (`targetRevision`).
        *   Which Kubernetes cluster and namespace to deploy to (`destination`).
        *   How to sync the manifests (`syncPolicy`).

2.  **Git Repository**:
    *   The Git repository (`https://github.com/argoproj/argocd-example-apps.git` in this case) contains the Kubernetes manifests for the guestbook application (`deployment.yaml`, `service.yaml`, etc.).

3.  **Synchronization**:
    *   ArgoCD continuously monitors the Git repository.
    *   When it detects a difference between the manifests in the repository and the live state in the cluster, it reports that the application is "OutOfSync".
    *   Because the `syncPolicy` is set to `automated`, ArgoCD will automatically sync the manifests, applying the changes to the cluster to bring it to the desired state defined in Git.

4.  **The GitOps Workflow**:
    *   To update the application, a developer would create a pull request with changes to the Kubernetes manifests in the Git repository.
    *   Once the pull request is reviewed and merged, ArgoCD automatically deploys the changes.
    *   This provides a clear, auditable, and automated path for application deployments.

## 🚀 How to Use This Example

### Prerequisites

*   **A Kubernetes Cluster**: You need a running Kubernetes cluster.
*   **ArgoCD Installed**: You need to have ArgoCD installed in your cluster. You can follow the [ArgoCD Getting Started guide](https://argo-cd.readthedocs.io/en/stable/getting_started/).
*   **kubectl**: Installed and configured to connect to your cluster.

### Steps

1.  **Save the manifests**:
    *   You can save the `application.yaml`, `deployment.yaml`, and `service.yaml` files from this directory to your local machine.

2.  **Apply the ArgoCD Application**:
    *   First, you need to apply the `application.yaml` to your cluster. This will create the ArgoCD application resource.
        ```sh
        kubectl apply -f application.yaml -n argocd
        ```

3.  **View the Application in the ArgoCD UI**:
    *   Open the ArgoCD UI (e.g., by using `kubectl port-forward` to access the `argocd-server` service).
    *   You should see the `guestbook-app` application. Initially, it might be "OutOfSync".
    *   ArgoCD will then automatically sync the application, and you will see the `guestbook-ui` deployment and service being created in the `guestbook` namespace.

4.  **Make a Change (The GitOps Way)**:
    *   To see the GitOps workflow in action, you would fork the `argocd-example-apps` repository, make a change to the `guestbook/guestbook-ui-deployment.yaml` (e.g., change the number of replicas), and push the change to your fork.
    *   You would then update the `repoURL` in your `application.yaml` to point to your fork and apply the change.
    *   ArgoCD would automatically detect the change and update the deployment in your cluster.
