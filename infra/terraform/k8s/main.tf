terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig
    config_context = var.kube_context
  }
}

locals {
  chart_path = abspath("${path.module}/../../kube/helm/canvas")
}

resource "helm_release" "canvas" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true

  chart = local.chart_path

  values = concat(
    var.values_files,
    [
      yamlencode({
        image = {
          repository = var.image_repository
          tag        = var.image_tag
        }
        postgres = {
          enabled = var.postgres_enabled
        }
        redis = {
          enabled = var.redis_enabled
        }
      })
    ]
  )

  dynamic "set" {
    for_each = var.set_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
