provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }

  # registries = [
  #   {
  #     url      = "oci://localhost:5000"
  #     username = "username"
  #     password = "password"
  #   },
  #   {
  #     url      = "oci://private.registry"
  #     username = "username"
  #     password = "password"
  #   }
  # ]
}


# terraform {
#   required_providers {
#   }
# }



provider "kubernetes" {
  config_path = "~/.kube/config"
}

terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.37.1"
    }
 
  }

  
}

resource "helm_release" "argocd" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"
}


variable "cloudflare_token" {
  type      = string
  sensitive = true
}

resource "kubernetes_secret" "cloudflare_token" {
  metadata {
    name      = "cloudflare-token"
    namespace = "girus"
  }

  data = {
    token = var.cloudflare_token
  }

  type = "Opaque"
}

resource "kubectl_manifest" "cluster_boostrap" {
  yaml_body = file("./argocd/applicationSet.yaml")
  depends_on = [ helm_release.argocd, kubernetes_secret.cloudflare_token ]
}

resource "null_resource" "wait_for_nginx" {
  depends_on = [kubectl_manifest.cluster_boostrap]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for NGINX pods to be ready..."
      kubectl wait --namespace ingress-nginx --for=create pod --selector=app.kubernetes.io/component=controller --timeout=60s
      kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
    EOT
  }
}

resource "null_resource" "wait_for_cert_manager" {
  depends_on = [kubectl_manifest.cluster_boostrap]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for NGINX pods to be ready..."
      kubectl wait --namespace cert-manager pod --for=create -l app.kubernetes.io/instance=cert-manager --timeout 60s
      kubectl wait --namespace cert-manager pod --for=condition=Ready -l app.kubernetes.io/instance=cert-manager --timeout 60s
    EOT
  }
}

# resource "kubectl_manifest" "app_of_apps" {
#   yaml_body = file("./argocd/applicationSet.yaml")
#   depends_on = [ helm_release.argocd ]
# }
