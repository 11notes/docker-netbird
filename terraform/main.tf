terraform {
  required_version = ">= 1.15.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

variable "postgres_password" {
  type = string
  sensitive = true
}

variable "netbird_fqdn" {
  type = string
}

resource "kubernetes_namespace_v1" "netbird" {
  metadata {
    name = "netbird"
  }
}

resource "kubernetes_secret_v1" "postgres_password" {
  metadata {
    name = "netbird-postgres-password"
    namespace = "netbird"
  }

  data = {
    POSTGRES_PASSWORD = trimspace(var.postgres_password)
  }

  type = "Opaque"
}

resource "helm_release" "netbird_db" {
  name = "netbird-db"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "postgres"
  namespace  = "netbird"
  version = "1.0.0"

  wait = true
  wait_for_jobs = true
  timeout = 300

  values = [
    yamlencode({
      image = {
        tag = "18"
      }
      postgres = {
        existingSecret = "netbird-postgres-password"
        existingSecretKey = "POSTGRES_PASSWORD"
      }
      persistence = {
        etc = {
          size = "16Mi"
        }
        var = {
          size = "32Gi"
        }
      }
    })
  ]
}

resource "helm_release" "netbird" {
  name = "netbird"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "netbird"
  namespace = "netbird"
  version = "0.0.1"

  values = [
    yamlencode({
      image = {
        tag = "0.76.1"
      }
      netbird = {
        fqdn = trimspace(var.netbird_fqdn)
      }
      postgres = {
        existingSecret = "netbird-postgres-password"
        existingSecretKey = "POSTGRES_PASSWORD"
        serviceName = "netbird-db-postgres"
      }
      persistence = {
        netbird-etc = {
          size = "16Mi"
        }
        netbird-var = {
          size = "2Gi"
        }
        dashboard-var = {
          size = "256Mi"
        }
      }
    })
  ]

  depends_on = [helm_release.netbird_db]
}