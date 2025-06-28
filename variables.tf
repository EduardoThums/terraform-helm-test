variable "rackspace_spot_token" {
  description = "Rackspace Spot authentication token"
  type        = string
  sensitive   = true
}

variable "cloudspace_name" {
  description = "The name of the cloudspace in Rackspace"
  type        = string
  default = "girus"
}

variable "spot_cloudspace_region" {
  description = "Region for the cloudspace spot"
  type        = string
  default = "us-central-dfw-1"
}

variable "spot_cloudspace_server_count" {
  description = "The desired count of servers to be running"
  type        = number
  default = 1
}

variable "kubeconfig_path" {
  description = "The path for the kubeconfig file"
  type        = string
  default = "~/.kube/config"
}

variable "cloudflare_token" {
  type      = string
  sensitive = true
}
