# Module to deploy Higly Availabe ArgoCD via HelmChart to AWS

Example to use:

```
module "argocd" {
  source           = "./terraform_argocd_eks"
  eks_cluster_name = "demo-dev"
  chart_version    = "9.1.6"
}
```

Copyleft (c) by Vladislav Golic.