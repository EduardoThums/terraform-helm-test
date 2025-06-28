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

    spot = {
      source = "rackerlabs/spot"
    }
 
  }  
}

provider "spot" {
  token = var.rackspace_spot_token
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}


# Example of cloudspace resource.
resource "spot_cloudspace" "example" {
  cloudspace_name = var.cloudspace_name
  # You can find the available region names in the `regions` data source.
  region             = var.spot_cloudspace_region
  hacontrol_plane    = false
#   preemption_webhook = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
  wait_until_ready   = true
  kubernetes_version = "1.31.1"
  cni                = "calico"
}

# Creates a spot node pool with an autoscaling pool of 3-8 servers of class gp.vs1.large-dfw.
resource "spot_spotnodepool" "autoscaling-bid" {
  cloudspace_name = resource.spot_cloudspace.example.cloudspace_name
  # You can find the available server classes in the `serverclasses` data source.
  server_class = "gp.vs1.large-dfw"
  bid_price    = 0.02
  desired_server_count = var.spot_cloudspace_server_count
}

data "spot_kubeconfig" "example" {
  cloudspace_name = var.cloudspace_name
  depends_on      = [spot_cloudspace.example]
}

locals {
  kubeconfig_path = pathexpand(var.kubeconfig_path)
}

# Updates the kubeconfig file with a new token each time `terraform apply` is executed.
resource "local_file" "kubeconfig" {
  depends_on = [data.spot_kubeconfig.example]
  count      = 1
  content    = data.spot_kubeconfig.example.raw
  filename   = local.kubeconfig_path
}


resource "null_resource" "wait_for_nodes_ready" {
  depends_on = [spot_cloudspace.example]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for ${var.spot_cloudspace_server_count} Kubernetes nodes to be Ready..."
      for i in {1..20}; do
        ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready ")
        if [ "$ready" -eq "${var.spot_cloudspace_server_count}" ]; then
          echo "All $ready nodes are Ready."
          exit 0
        fi
        echo "Currently Ready: $ready / ${var.spot_cloudspace_server_count} — retrying ($i)..."
        sleep 60
      done
      echo "Timeout waiting for ${var.spot_cloudspace_server_count} nodes to become Ready."
      exit 1
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

resource "helm_release" "argocd" {
  depends_on = [ null_resource.wait_for_nodes_ready ]

  name       = "argo"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  create_namespace = true
  namespace = "argocd"
  wait = true # Will wait until all resources are in a ready state before marking the release as successful.
  values = [file("./argocd/values.yaml")]
}

resource "kubernetes_namespace" "girus" {
  metadata {
    name      = "girus"
  }
}

resource "kubernetes_secret" "cloudflare_token" {
  depends_on = [ kubernetes_namespace.girus ]

  metadata {
    name      = "cloudflare-token"
    namespace = kubernetes_namespace.girus.metadata[0].name
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
