{{/*
Expand the name of the chart.
*/}}
{{- define "netbird.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "netbird.fullname" -}}
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
{{- define "netbird.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "netbird.labels" -}}
helm.sh/chart: {{ include "netbird.chart" . }}
{{ include "netbird.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "netbird.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netbird.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the Secret holding POSTGRES_PASSWORD.
*/}}
{{- define "postgres.secretName" -}}
{{- if .Values.postgres.existingSecret }}
{{- .Values.postgres.existingSecret }}
{{- else }}
{{- include "netbird.fullname" . }}
{{- end }}
{{- end }}

{{/*
Key within the Secret holding POSTGRES_PASSWORD.
*/}}
{{- define "postgres.secretKey" -}}
{{- if .Values.postgres.existingSecret }}
{{- .Values.postgres.existingSecretKey | default "POSTGRES_PASSWORD" }}
{{- else }}
{{- "POSTGRES_PASSWORD" }}
{{- end }}
{{- end }}

{{/*
Claim name for a given persistence volume (etc).
*/}}
{{- define "netbird.claimName" -}}
{{- $root := index . 0 }}
{{- $vol := index . 1 }}
{{- $cfg := index $root.Values.persistence $vol }}
{{- if $cfg.existingClaim }}
{{- $cfg.existingClaim }}
{{- else }}
{{- printf "%s-%s" (include "netbird.fullname" $root) $vol }}
{{- end }}
{{- end }}
