terraform {
  required_version = ">= 1.15.0"
  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 3.2"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
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

variable "netbird_fqdn" {
  type = string
}

variable "wildcard_fqdn" {
  type = string
}

variable "stun_ingress_ip" {
  type = string
}

variable "postgres_password" {
  type = string
  sensitive = true
}

resource "kubernetes_namespace_v1" "netbird" {
  metadata {
    name = "netbird"
  }
}

resource "kubernetes_secret_v1" "postgres_password" {
  metadata {
    name = "postgres-password"
    namespace = "netbird"
  }

  data = {
    POSTGRES_PASSWORD = trimspace(var.postgres_password)
  }

  type = "Opaque"
}

resource "kubernetes_ingress_v1" "netbird_ingress_grpc" {
  metadata {
    name = "netbird-ingress-grpc"
    namespace = "netbird"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      "traefik.ingress.kubernetes.io/service.serversscheme" = "h2c"
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts = [trimspace(var.netbird_fqdn)]
      secret_name = "wildcard-${replace(trimspace(var.wildcard_fqdn), ".", "-")}-tls"
    }

    rule {
      host = trimspace(var.netbird_fqdn)
      http {
        path {
          path = "/signalexchange.SignalExchange/"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/management.ManagementService/"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/management.ProxyService/"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "netbird_ingress_ws" {
  metadata {
    name = "netbird-ingress-ws"
    namespace = "netbird"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts = [trimspace(var.netbird_fqdn)]
      secret_name = "wildcard-${replace(trimspace(var.wildcard_fqdn), ".", "-")}-tls"
    }

    rule {
      host = trimspace(var.netbird_fqdn)
      http {
        path {
          path = "/relay"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/ws-proxy"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/api"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/oauth2"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird"
              port {
                number = 8080
              }
            }
          }
        }
        path {
          path = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "netbird-dashboard"
              port {
                number = 3000
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "netbird_ingress_stun" {
  metadata {
    name = "netbird-ingress-stun"
    namespace = "netbird"
    annotations = {
      "metallb.io/loadBalancerIPs" = "{trimspace(var.stun_ingress_ip)}"
    }
  }
  spec {
    type = "LoadBalancer"
    external_traffic_policy = "Local"
    selector = {
      "app.kubernetes.io/instance" = "netbird"
      "app.kubernetes.io/name" = "netbird"
    }
    port {
      name = "netbird-stun"
      protocol = "UDP"
      port = 3478
      target_port = 3478
    }
  }
}

resource "helm_release" "netbird_db" {
  name = "postgres"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "postgres"
  namespace = "netbird"
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
        existingSecret = "postgres-password"
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

resource "helm_release" "netbird_dashboard" {
  name = "netbird-dashboard"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "netbird-dashboard"
  namespace = "netbird"
  version = "1.0.0"

  values = [
    yamlencode({
      image = {
        tag = "0.76.1"
      }
      netbird = {
        fqdn = trimspace(var.netbird_fqdn)
      }
      persistence = {
        var = {
          size = "256Mi"
        }
      }
    })
  ]

  depends_on = [helm_release.netbird_db]
}

resource "helm_release" "netbird" {
  name = "netbird"
  repository = "oci://ghcr.io/11notes/charts"
  chart = "netbird"
  namespace = "netbird"
  version = "1.0.0"

  values = [
    yamlencode({
      service = {
        annotations = {
          "traefik.ingress.kubernetes.io/service.serversscheme" = "h2c"
        }
      }
      image = {
        tag = "0.76.1"
      }
      netbird = {
        fqdn = trimspace(var.netbird_fqdn)
      }
      postgres = {
        existingSecret = "postgres-password"
        existingSecretKey = "POSTGRES_PASSWORD"
        serviceName = "postgres"
      }
      persistence = {
        etc = {
          size = "16Mi"
        }
        var = {
          size = "2Gi"
        }
      }
    })
  ]

  depends_on = [helm_release.netbird_dashboard]
}