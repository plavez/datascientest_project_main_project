terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Провайдер Kubernetes использует kubeconfig (как kubectl)
provider "kubernetes" {
  config_path = var.kubeconfig_path
}

# Создаём корневое ArgoCD-приложение (App-of-Apps / root application)
resource "kubernetes_manifest" "argocd_root" {
  manifest = yamldecode(
    templatefile("${path.module}/root.yaml", {
      path           = var.git_source_path
      repoURL        = var.git_source_repoURL
      targetRevision = var.git_source_targetRevision
    })
  )
}
