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

