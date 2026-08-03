{{/*
Expand the name of the chart.
*/}}
{{- define "netbird-dashboard.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "netbird-dashboard.fullname" -}}
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
Chart name and version label.
*/}}
{{- define "netbird-dashboard.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "netbird-dashboard.labels" -}}
helm.sh/chart: {{ include "netbird-dashboard.chart" . }}
{{ include "netbird-dashboard.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "netbird-dashboard.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netbird-dashboard.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Claim name for a given persistence volume (etc).
*/}}
{{- define "netbird-dashboard.claimName" -}}
{{- $root := index . 0 }}
{{- $vol := index . 1 }}
{{- $cfg := index $root.Values.persistence $vol }}
{{- if $cfg.existingClaim }}
{{- $cfg.existingClaim }}
{{- else }}
{{- printf "%s-%s" (include "netbird-dashboard.fullname" $root) $vol }}
{{- end }}
{{- end }}