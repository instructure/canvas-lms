# Canvas Kubernetes Terraform Module

This Terraform configuration bootstraps the Canvas Helm chart into an existing
Kubernetes cluster. It assumes you already have a Kubernetes control plane
(minikube, kind, k3d, cloud provider, etc.) and a working kubeconfig.

## Quick start

```bash
cd infra/terraform/k8s
terraform init
terraform apply \
  -var="kubeconfig=~/.kube/config" \
  -var="namespace=canvas-dev" \
  -var="image_repository=canvas-lms:latest"
```

By default the chart installs lightweight Postgres and Redis deployments. Set
`postgres_enabled=false` or `redis_enabled=false` to use external services.

To remove everything:

```bash
terraform destroy
```

## Variables

| Name | Description | Default |
| --- | --- | --- |
| `kubeconfig` | Path to kubeconfig file Terraform should use | `~/.kube/config` |
| `kube_context` | Optional kubeconfig context | `` |
| `namespace` | Namespace to install Canvas into | `canvas-dev` |
| `release_name` | Helm release name | `canvas` |
| `values_files` | Extra Helm values files | `[]` |
| `set_values` | Map of key/value overrides passed via `--set` | `{}` |
| `image_repository` | Container image for Canvas workloads | `canvas-lms:latest` |
| `image_tag` | Image tag (blank uses chart default) | `` |
| `postgres_enabled` | Deploy in-cluster Postgres for development | `true` |
| `redis_enabled` | Deploy in-cluster Redis for development | `true` |
