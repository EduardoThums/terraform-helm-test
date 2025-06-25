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


terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
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


resource "kubectl_manifest" "test" {
  yaml_body = file("./argocd/applicationSet.yaml")
  depends_on = [ helm_release.argocd ]
}
