terraform {
  required_version = ">= 1.6.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

resource "null_resource" "kind_cluster" {
  triggers = {
    cluster_name = var.cluster_name
    kind_config  = filesha256(var.kind_config)
  }

  provisioner "local-exec" {
    command = "kind get clusters | grep -qx '${var.cluster_name}' || kind create cluster --name '${var.cluster_name}' --config '${var.kind_config}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name '${self.triggers.cluster_name}'"
  }
}