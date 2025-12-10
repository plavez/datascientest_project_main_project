output "argocd_version" {
  value = helm_release.argocd.metadata.app_version
}

output "helm_revision" {
  value = helm_release.argocd.metadata.revision
}

output "chart_version" {
  value = helm_release.argocd.metadata.version
}
