variable "kubeconfig" {
  description = "Path to kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Optional kubeconfig context"
  type        = string
  default     = ""
}

variable "namespace" {
  description = "Namespace to install Canvas into"
  type        = string
  default     = "canvas-dev"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "canvas"
}

variable "values_files" {
  description = "Additional Helm values files"
  type        = list(string)
  default     = []
}

variable "set_values" {
  description = "Map of string overrides passed via --set"
  type        = map(string)
  default     = {}
}

variable "image_repository" {
  description = "Canvas container image repository"
  type        = string
  default     = "canvas-lms:latest"
}

variable "image_tag" {
  description = "Canvas container image tag"
  type        = string
  default     = ""
}

variable "postgres_enabled" {
  description = "Deploy chart-managed Postgres"
  type        = bool
  default     = true
}

variable "redis_enabled" {
  description = "Deploy chart-managed Redis"
  type        = bool
  default     = true
}
