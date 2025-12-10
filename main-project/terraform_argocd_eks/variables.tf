variable "kubeconfig_path" {
  description = "Path to kubeconfig file for the target k3s cluster"
  type        = string
}

variable "chart_version" {
  description = "Helm Chart Version of ArgoCD: https://github.com/argoproj/argo-helm/releases"
  type        = string
  default     = "9.1.6"
}
# variable "eks_cluster_name" {
#   description = "EKS Cluster name to deploy ArgoCD"
#   type        = string
# }

# variable "chart_version" {
#   description = "Helm Chart Version of ArgoCD: https://github.com/argoproj/argo-helm/releases"
#   type        = string
#   default     = "5.46.0"
# }
