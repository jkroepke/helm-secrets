terraform {
  required_version = ">= 0.14"

  required_providers {
    helm = {}
    random = {}
    null = {}
    sops = {
      source = "carlpett/sops"
    }
  }
}
