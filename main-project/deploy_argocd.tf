## First step deploying
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



# ## Second step deploying
# ## Can be deployed ONLY after ArgoCD deployment: depends_on = [module.argocd_dev]
# ## Root для DEV
# module "argocd_dev_root" {
#   source          = "./terraform_argocd_root_eks"
#   kubeconfig_path = pathexpand("~/.kube/dev-k3s.yaml")

#   git_source_path           = "dev/applications"
#   git_source_repoURL        = "https://github.com/plavez/argocd.git"
#   git_source_targetRevision = "main"
# }

# ### Can be deployed ONLY after ArgoCD deployment: depends_on = [module.argocd_prod]
# ### Root для PROD
# module "argocd_prod_root" {
#   source          = "./terraform_argocd_root_eks"
#   kubeconfig_path = pathexpand("~/.kube/prod-k3s.yaml")

#   git_source_path           = "prod/applications"
#   git_source_repoURL        = "https://github.com/plavez/argocd.git"
#   git_source_targetRevision = "main"
# }
