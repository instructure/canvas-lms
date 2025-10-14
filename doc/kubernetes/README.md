# Running Canvas on Kubernetes

This repository now ships a lightweight Helm chart intended for development
clusters. It mirrors the docker-compose setup (web, webpack, delayed_job,
Postgres, Redis) using simple Deployments.

## Prerequisites

- A Kubernetes cluster (minikube, kind, k3d, cloud provider, etc.)
- `kubectl` configured for the target cluster
- Helm 3.x

## Install via Helm

```bash
# from repo root
make k8s-helm-install

# forward the web port locally
make k8s-port-forward

# or run helm/kubectl manually
helm upgrade --install canvas kube/helm/canvas \
  --namespace canvas-dev \
  --create-namespace
kubectl port-forward svc/canvas-canvas-web 3000:3000
```

The chart defaults to development settings. Update `values.yaml` or pass
`--set`/`--values` overrides to adjust the container image, Postgres/Redis
configuration, or Canvas environment variables.

## Install via Terraform

A Terraform module automates the Helm deployment and handles namespace creation.

```bash
make k8s-apply
```

Override variables in `terraform.tfvars` or via `-var` flags. To remove the
release:

```bash
make k8s-destroy
```

## Notes

- The bundled Postgres and Redis pods use ephemeral storage by default
  (`emptyDir`). Enable persistence in `values.yaml` for longer-lived clusters.
- Canvas expects precompiled assets. Build and push an image containing the
  latest code before deploying, or mount volumes in the chart to supply them.
- For production deployments you should harden the configuration (persistent
  volumes, external databases, TLS ingress, secrets management, etc.).
