{{- define "canvas.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{- define "canvas.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "canvas.componentName" -}}
{{- printf "%s-%s" (include "canvas.fullname" .root) .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "canvas.image" -}}
{{- $repo := .root.Values.image.repository -}}
{{- $tag := .root.Values.image.tag -}}
{{- if ne $tag "" -}}
{{- printf "%s:%s" $repo $tag -}}
{{- else -}}
{{- $repo -}}
{{- end -}}
{{- end -}}

{{- define "canvas.postgresHost" -}}
{{- if .Values.postgres.enabled -}}
{{- printf "%s" (include "canvas.componentName" (dict "root" . "component" "postgres")) -}}
{{- else -}}
{{- default "" .Values.postgres.host -}}
{{- end -}}
{{- end -}}

{{- define "canvas.redisHost" -}}
{{- if .Values.redis.enabled -}}
{{- printf "%s" (include "canvas.componentName" (dict "root" . "component" "redis")) -}}
{{- else -}}
{{- default "" .Values.redis.host -}}
{{- end -}}
{{- end -}}

{{- define "canvas.postgresSecretName" -}}
{{- printf "%s" (include "canvas.componentName" (dict "root" . "component" "postgres")) -}}
{{- end -}}

{{- define "canvas.securitySecretName" -}}
{{- printf "%s-security" (include "canvas.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
