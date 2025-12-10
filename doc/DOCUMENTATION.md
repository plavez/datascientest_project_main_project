# Multi-Cluster GitOps with Argo CD, Helm and Terraform
1. ## Overview

    This project deploys a GitOps setup on two Kubernetes clusters (dev & prod) running on AWS EC2:

    k3s clusters (dev and prod) on EC2

    Argo CD installed via Terraform + Helm

    Applications deployed via Argo CD Applications using the App-of-Apps (Root Application) pattern

    All manifests and Helm charts stored in a Git repository (plavez/argocd)

    Deployment is done in two stages:

    Install Argo CD into both clusters

    Create Root Applications which instruct Argo CD to deploy all other apps from Git

    The sections below describe all steps in detail.

---

2. ## Prerequisites

    Before starting, ensure you have:

    AWS account and credentials configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, correct region)

    A Linux shell (or WSL) with:

    terraform (v1.x)

    kubectl

    helm

    git

    SSH access to GitHub (or HTTPS access if you use HTTPS URLs)

    Two k3s clusters will be created:

    dev cluster

    prod cluster

    **Throughout the documentation the working directory is:**
    ```
    ~/datascientest-main-project/main-project


    ```
    You can adapt it if your path is different.

    ---

3. ## Stage 1 – Provisioning k3s Clusters on AWS EC2

    If your clusters are already created and you already have kubeconfig files
    ~/.kube/dev-k3s.yaml and ~/.kube/prod-k3s.yaml, you can skip to Stage 2.

   1.  ### Terraform Structure (clusters)
       The infrastructure for k3s clusters is defined in a separate Terraform project (for example k3s-aws), which:

        creates:

                1 master + 2 worker nodes for dev

                1 master + 2 worker nodes for prod

        installs k3s on each node

        generates kubeconfig files:

                ~/.kube/dev-k3s.yaml

                ~/.kube/prod-k3s.yaml

    2.  ### Cluster Provisioning Commands
       **From the cluster Terraform directory (e.g. ~/k3s-aws):**
       ```
        terraform init
        terraform plan
        terraform apply
       ```
       Wait until Terraform finishes.

    3.  ### Verifying Clusters
        Export kubeconfig and check nodes.

        **Dev cluster**
        ```
        export KUBECONFIG=~/.kube/dev-k3s.yaml
        kubectl get nodes

        ```
       You should see 3 nodes, one of them with role control-plane,master.

       **Prod cluster**
       ```
       export KUBECONFIG=~/.kube/prod-k3s.yaml
       kubectl get nodes

       ```
       Again, 3 Ready nodes should be displayed.

       Once both clusters are reachable, proceed to Argo CD installation.

4. ## Stage 2 – Installing Argo CD with Terraform + Helm

   **All Argo CD related Terraform code is located in the main project directory:**
   ```
    main-project/
    ├── deploy_argocd.tf
    └── terraform_argocd_eks/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── argocd.yaml          # Argo CD values (HA, autoscaling, etc.)

   ```
    1. ### Module terraform_argocd_eks

       This module:

       connects to a target k3s cluster via kubeconfig

       configures the helm provider

       installs the official Argo CD Helm chart (argo-cd) into namespace argocd

       applies additional configuration from argocd.yaml (HA, autoscaling, health checks)

       **Key parts:**
       ```
       data "aws_eks_cluster" "this" { ... }          # in your case: equivalent config via kubeconfig
       provider "helm" {
         kubernetes {
             host                   = ...
             token                  = ...
             cluster_ca_certificate = ...
         }
       }

        resource "helm_release" "argocd" {
        name       = "argocd"
        repository = "https://argoproj.github.io/argo-helm"
        chart      = "argo-cd"
        version    = var.chart_version
        namespace  = "argocd"
        values     = [file("${path.module}/argocd.yaml")]
        }
       ```
       (Your actual code is adapted for k3s using kubeconfig.)

    2. ### deploy_argocd.tf – Argo CD for dev and prod

       **deploy_argocd.tf defines two module instances:**
       ```
       module "argocd_dev" {
        source          = "./terraform_argocd_eks"
        kubeconfig_path = pathexpand("~/.kube/dev-k3s.yaml")
        chart_version   = "9.1.6"
        }

       module "argocd_prod" {
        source          = "./terraform_argocd_eks"
        kubeconfig_path = pathexpand("~/.kube/prod-k3s.yaml")
        chart_version   = "9.1.5"
        }
       ```

    3. ### Argo CD Installation Commands
       **From ~/datascientest-main-project/main-project:**
       ```
       terraform init
       terraform plan -target=module.argocd_dev -target=module.argocd_prod
       terraform apply -target=module.argocd_dev -target=module.argocd_prod

       ```
       Terraform will:

       connect to both clusters

       create namespace argocd

       install Argo CD via Helm into dev and prod clusters

    4. ###  Verify Argo CD Pods
       **Dev cluster**
       ```
       export KUBECONFIG=~/.kube/dev-k3s.yaml
       kubectl get pods -n argocd

       ```
       Pods should also be in Running state.

    5. ### Accessing Argo CD UI
       For local access you can use port-forwarding from your workstation.

       **Example (dev cluster):**
       ```
       export KUBECONFIG=~/.kube/dev-k3s.yaml
       kubectl port-forward svc/argocd-server -n argocd 8080:443

       ```
       **Then open in browser:**
       ```
       https://localhost:8080

       ```
       Use user admin and this password to log in.

       (You can repeat same procedure for the prod cluster if needed.)

5. ## Stage 3 – Deploying Applications via Argo CD (App-of-Apps)

    1. ### Git Repository Structure
       All application manifests and Helm charts are stored in GitHub repo
       https://github.com/plavez/argocd.
       **Structure:**
       ```
        argocd/
        ├── dev/
        │   └── applications/
        │        ├── app1.yaml
        │        ├── app2.yaml
        │        └── root.yaml
        │
        ├── prod/
        │   └── applications/
        │        ├── app1.yaml
        │        ├── app2.yaml
        │        └── root.yaml
        │
        └── HelmCharts/
            ├── MyChart1/
            │    ├── Chart.yaml
            │    ├── templates/
            │    └── values_dev.yaml
            └── MyChart2/
                ├── Chart.yaml
                ├── templates/
                └── values_dev.yaml
       ```

       dev/applications – Argo CD Application resources for dev

       prod/applications – Argo CD Application resources for prod

       HelmCharts/ – Helm charts used by these applications






