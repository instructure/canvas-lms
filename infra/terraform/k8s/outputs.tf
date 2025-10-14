output "namespace" {
  value       = helm_release.canvas.namespace
  description = "Namespace where Canvas is deployed"
}

output "release_name" {
  value       = helm_release.canvas.name
  description = "Helm release name"
}
