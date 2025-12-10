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