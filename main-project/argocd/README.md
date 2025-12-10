# Argo CD on two kind clusters (dev & prod) via Terraform.Monitoring Prometheus - Grafana.

This repo deploys **Argo CD** into two local **kind** Kubernetes clusters — `dev` and `prod` — using **Terraform** and the **App-of-Apps** (Root Application) pattern.

One `terraform apply` spins up:
- `argocd-dev` release in the `kind-dev` cluster (namespace `argocd-dev`)
- `argocd-prod` release in the `kind-prod` cluster (namespace `argocd-prod`)
- a Root `Application` in each namespace that syncs apps from a Git repo

---

## Requirements

- Docker Desktop (WSL2 backend on Windows is fine)
- [`kind`](https://kind.sigs.k8s.io/) ≥ 0.20  
- `kubectl`
- Terraform ≥ 1.5
- (optional) `helm`, `argocd` CLI, `git`

> Tip: allocate ~16–24 GB RAM to Docker/WSL for a smooth local experience.

---

## Repository layout


##argocd
```
│
├── HelmCharts             # All Helm Charts
│   ├── ChartTest1
│   │   ├── Chart.yaml
│   │   ├── templates
│   │   ├── values_dev.yaml    # DEV Values
│   │   ├── values_prod.yaml   # PROD Values
│   │   └── values.yaml        # Default Values
│   └── ChartTest2
│       ├── Chart.yaml
│       ├── templates
│       ├── values_dev.yaml    # DEV Values
│       ├── values_prod.yaml   # PROD Values
│       └── values.yaml        # Default Values
│   
├── dev                        # Cluster name
│   ├── applications
│   │   ├── app1.yaml
│   │   └── app2.yaml
│   └── root.yaml              # Root ArgoCD Application
└── prod                       # Cluster name
    ├── applications
    │   ├── app1.yaml
    │   └── app2.yaml
    └── root.yaml              # Root ArgoCD Application    
```