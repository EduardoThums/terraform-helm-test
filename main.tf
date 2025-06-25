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

resource "helm_release" "nginx_ingress" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"

  # set = [
  #   {
  #     name  = "service.type"
  #     value = "ClusterIP"
  #   }
  # ]
}

resource "helm_release" "cluster_boostrap" {
  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"

  # set = [
  #   {
  #     name  = "service.type"
  #     value = "ClusterIP"
  #   }
  # ]
}