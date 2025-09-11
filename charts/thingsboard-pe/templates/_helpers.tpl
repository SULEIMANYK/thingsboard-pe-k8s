{{/*
Expand the name of the chart.
*/}}
{{- define "thingsboard-pe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "thingsboard-pe.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "thingsboard-pe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "thingsboard-pe.labels" -}}
helm.sh/chart: {{ include "thingsboard-pe.chart" . }}
{{ include "thingsboard-pe.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "thingsboard-pe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "thingsboard-pe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "thingsboard-pe.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "thingsboard-pe.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the namespace name
*/}}
{{- define "thingsboard-pe.namespace" -}}
{{- if .Values.namespace.create }}
{{- default "thingsboard" .Values.namespace.name }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Get the storage class name
*/}}
{{- define "thingsboard-pe.storageClass" -}}
{{- if .Values.global.oracle.storageClass }}
{{- .Values.global.oracle.storageClass }}
{{- else }}
{{- "oci-bv" }}
{{- end }}
{{- end }}

{{/*
Get the database secret name
*/}}
{{- define "thingsboard-pe.databaseSecretName" -}}
{{- if .Values.database.existingSecret }}
{{- .Values.database.existingSecret }}
{{- else }}
{{- printf "%s-db" (include "thingsboard-pe.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the license secret name
*/}}
{{- define "thingsboard-pe.licenseSecretName" -}}
{{- if .Values.global.license.existingSecret }}
{{- .Values.global.license.existingSecret }}
{{- else }}
{{- printf "%s-license" (include "thingsboard-pe.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Get the cache secret name
*/}}
{{- define "thingsboard-pe.cacheSecretName" -}}
{{- if .Values.cache.redis.existingSecret }}
{{- .Values.cache.redis.existingSecret }}
{{- else }}
{{- printf "%s-cache" (include "thingsboard-pe.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Oracle Cloud Load Balancer annotations
*/}}
{{- define "thingsboard-pe.loadBalancerAnnotations" -}}
{{- if .Values.global.oracle.loadBalancer.enabled }}
service.beta.kubernetes.io/oci-load-balancer-shape: {{ .Values.global.oracle.loadBalancer.shape | quote }}
service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: {{ .Values.global.oracle.loadBalancer.minBandwidth | quote }}
service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: {{ .Values.global.oracle.loadBalancer.maxBandwidth | quote }}
{{- end }}
{{- end }}

{{/*
Component-specific labels
*/}}
{{- define "thingsboard-pe.componentLabels" -}}
{{- $component := .component }}
{{- with .root }}
{{ include "thingsboard-pe.labels" . }}
app.kubernetes.io/component: {{ $component }}
{{- end }}
{{- end }}

{{/*
Component-specific selector labels
*/}}
{{- define "thingsboard-pe.componentSelectorLabels" -}}
{{- $component := .component }}
{{- with .root }}
{{ include "thingsboard-pe.selectorLabels" . }}
app.kubernetes.io/component: {{ $component }}
{{- end }}
{{- end }}

{{/*
Security context
*/}}
{{- define "thingsboard-pe.securityContext" -}}
runAsUser: {{ .Values.securityContext.runAsUser }}
runAsNonRoot: {{ .Values.securityContext.runAsNonRoot }}
fsGroup: {{ .Values.securityContext.fsGroup }}
{{- end }}

{{/*
Pod anti-affinity rules
*/}}
{{- define "thingsboard-pe.podAntiAffinity" -}}
{{- if .Values.affinity.podAntiAffinity.enabled }}
podAntiAffinity:
  {{- if .Values.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution }}
  requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
          - key: "app.kubernetes.io/component"
            operator: In
            values:
              - {{ .component }}
      topologyKey: {{ .Values.affinity.podAntiAffinity.topologyKey }}
  {{- else }}
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: "app.kubernetes.io/component"
              operator: In
              values:
                - {{ .component }}
        topologyKey: {{ .Values.affinity.podAntiAffinity.topologyKey }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Image pull policy
*/}}
{{- define "thingsboard-pe.imagePullPolicy" -}}
{{- default "Always" .Values.image.pullPolicy }}
{{- end }}

{{/*
Check if microservices mode is enabled
*/}}
{{- define "thingsboard-pe.isMicroservices" -}}
{{- eq .Values.global.deploymentMode "microservices" }}
{{- end }}

{{/*
Check if monolith mode is enabled
*/}}
{{- define "thingsboard-pe.isMonolith" -}}
{{- eq .Values.global.deploymentMode "monolith" }}
{{- end }}

{{/*
Get service type for transports
*/}}
{{- define "thingsboard-pe.transportServiceType" -}}
{{- if .Values.global.oracle.loadBalancer.enabled }}
{{- "LoadBalancer" }}
{{- else }}
{{- "ClusterIP" }}
{{- end }}
{{- end }}
