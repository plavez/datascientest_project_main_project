# Multi-Cluster GitOps with Argo CD, Helm and Terraform

## Overview

This project deploys a GitOps setup on two Kubernetes clusters (dev & prod) running on AWS EC2:

- k3s clusters (dev and prod) on EC2
- Argo CD installed via Terraform + Helm
- Applications deployed via Argo CD Applications using the App-of-Apps (Root Application) pattern
- All manifests and Helm charts stored in a Git repository (`plavez/argocd`)

Deployment is done in two stages:

1. Install Argo CD into both clusters
2. Create Root Applications which instruct Argo CD to deploy all other apps from Git

The sections below describe all steps in detail.

---

## Prerequisites

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

## Stage 1 – Provisioning k3s Clusters on AWS EC2

    If your clusters are already created and you already have kubeconfig files
    ~/.kube/dev-k3s.yaml and ~/.kube/prod-k3s.yaml, you can skip to Stage 2.

   1.  **Terraform Structure (clusters)**
       The infrastructure for k3s clusters is defined in a separate Terraform project (for example k3s-aws), which:

        creates:

                1 master + 2 worker nodes for dev

                1 master + 2 worker nodes for prod

        installs k3s on each node

        generates kubeconfig files:

                ~/.kube/dev-k3s.yaml

                ~/.kube/prod-k3s.yaml

    2. Cluster Provisioning Commands
       **From the cluster Terraform directory (e.g. ~/k3s-aws):**
       ```
        terraform init
        terraform plan
        terraform apply
       ```
       Wait until Terraform finishes.

    3.  Verifying Clusters
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

## Stage 2 – Installing Argo CD with Terraform + Helm

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
    1. Module terraform_argocd_eks

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

    2. deploy_argocd.tf – Argo CD for dev and prod

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

    3. Argo CD Installation Commands
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

    4. Verify Argo CD Pods
       **Dev cluster**
       ```
       export KUBECONFIG=~/.kube/dev-k3s.yaml
       kubectl get pods -n argocd

       ```
       Pods should also be in Running state.

    5. Accessing Argo CD UI
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

## Stage 3 – Deploying Applications via Argo CD (App-of-Apps)

    1. Git Repository Structure
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

    2. Example: Helm values (values_dev.yaml)
       ```
       # Dev Override Values for my Helm Chart

        container:
        image: nginx:1.27-alpine

        replicaCount: 4

        service:
        type: NodePort
        port: 80
        targetPort: 80
        nodePort: 30080

       ```


    3. Example: app1.yaml (dev)

       ```
        apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
        name: myapp1
        namespace: argocd-dev
        finalizers:
            - resources-finalizer.argocd.argoproj.io
        spec:
        destination:
            name: in-cluster
            namespace: app1
        source:
            repoURL: "https://github.com/plavez/argocd.git"
            path: "HelmCharts/MyChart1"
            targetRevision: main
            helm:
            valueFiles:
                - values_dev.yaml
            parameters:
                - name: "container.image"
                value: nginx:1.27-alpine
        project: default
        syncPolicy:
            automated:
            prune: true
            selfHeal: true
            syncOptions:
            - CreateNamespace=true
      ```

      app2.yaml is identical except for name, namespace and chart path (MyChart2).


    4. Root Application in Git (dev/applications/root.yaml)
       ```
       apiVersion: argoproj.io/v1alpha1
        kind: Application
        metadata:
        name: root
        namespace: argocd-dev
        finalizers:
            - resources-finalizer.argocd.argoproj.io
        spec:
        destination:
            name: in-cluster
            namespace: argocd-dev
        source:
            repoURL: "https://github.com/plavez/argocd.git"
            path: "dev/applications"
            targetRevision: main
        project: default
        syncPolicy:
            automated:
            prune: true
            selfHeal: true

      ```
      The prod root application is the same, but uses:

      namespace: argocd-prod

      path: "prod/applications"

    5. Terraform Module terraform_argocd_root_eks
       **This module applies a Root Application manifest to the cluster via kubernetes_manifest:**
       ```
        variable "kubeconfig_path"      { type = string }
        variable "git_source_repoURL"   { type = string }
        variable "git_source_path"      { type = string }
        variable "git_source_targetRevision" {
        type    = string
        default = "main"
        }

        provider "kubernetes" {
        config_path = var.kubeconfig_path
        }

        resource "kubernetes_manifest" "argocd_root" {
        manifest = yamldecode(templatefile("${path.module}/root.yaml", {
            repoURL        = var.git_source_repoURL
            path           = var.git_source_path
            targetRevision = var.git_source_targetRevision
        }))
        }
       ```

    6. Wiring it in deploy_argocd.tf
       **In deploy_argocd.tf we create two root modules:**
       ```
        # Root for DEV
        module "argocd_dev_root" {
        source          = "./terraform_argocd_root_eks"
        kubeconfig_path = pathexpand("~/.kube/dev-k3s.yaml")

        git_source_path          = "dev/applications"
        git_source_repoURL       = "https://github.com/plavez/argocd.git"
        git_source_targetRevision = "main"

        # Can be enabled if you want strict ordering:
        # depends_on = [module.argocd_dev]
        }

        # Root for PROD
        module "argocd_prod_root" {
        source          = "./terraform_argocd_root_eks"
        kubeconfig_path = pathexpand("~/.kube/prod-k3s.yaml")

        git_source_path          = "prod/applications"
        git_source_repoURL       = "https://github.com/plavez/argocd.git"
        git_source_targetRevision = "main"

        # depends_on = [module.argocd_prod]
        }

      ```

    7. Deploying Applications (Stage 2)

       **From ~/datascientest-main-project/main-project:**
       ```
       terraform plan
       terraform apply

       ```
        Now Terraform will:

        Confirm Argo CD Helm releases (dev & prod)

        Create Root Application in each cluster (argocd_dev_root / argocd_prod_root)

        Argo CD will:

        read your Git repo plavez/argocd

        load all application manifests from dev/applications and prod/applications

        create child Application resources (myapp1, myapp2, etc.)

        deploy Helm charts MyChart1, MyChart2 into clusters

    8. Verifying Applications
       In Kubernetes
         **Dev:**
       ```
       export KUBECONFIG=~/.kube/dev-k3s.yaml
       kubectl get applications.argoproj.io -A
       kubectl get pods -A

       ```
        **Prod:**
       ```
       export KUBECONFIG=~/.kube/prod-k3s.yaml
       kubectl get applications.argoproj.io -A
       kubectl get pods -A
       ```
       You should see:

       Application resources myapp1, myapp2, root

       Corresponding pods in namespaces app1, app2, etc.

       In Argo CD UI

       Log in to Argo CD UI (dev and prod)

       You should see tiles:

       root

       myapp1

       myapp2

       All of them should be in state Healthy and Synced.

## Destroying the Environment

    1. Destroy Only Applications and Argo CD
       **From main project directory:**

       ```
       terraform destroy
       ```
       This will:

       remove root Application resources

       remove all child Argo CD applications (myapp1, myapp2, etc.)

       uninstall Argo CD Helm releases

       keep your k3s clusters (EC2 instances) intact

       **If you encounter finalizer issues, you can manually remove them, for example:**
       ```
       export KUBECONFIG=~/.kube/dev-k3s.yaml
       kubectl patch application root -n argocd-dev \
       -p '{"metadata":{"finalizers":[]}}' --type=merge

       ```

    2. Destroy Clusters
       **From your k3s infrastructure Terraform directory (~/k3s-aws):**
       ```
       terraform destroy

       ```
       This will delete all EC2 instances and therefore remove both k3s clusters completely.

## Summary

   This documentation describes:

   How k3s clusters are provisioned on AWS EC2 using Terraform

   How Argo CD is installed into both dev and prod clusters using Helm via Terraform

   How applications are deployed using the App-of-Apps pattern:

   Root Application managed by Terraform (kubernetes_manifest)

   Child Applications managed by Argo CD from a Git repository

   How to verify and how to properly destroy all resources
