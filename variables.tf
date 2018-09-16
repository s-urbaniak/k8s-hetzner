variable "node_image" {
  description = "Predefined Image that will be used to spin up the machines (Currently supported: ubuntu-16.04, debian-9,centos-7,fedora-27)"
  default     = "ubuntu-16.04"
}

variable "master_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx11"
}

variable "ingress_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx11"
}

variable "worker_type" {
  description = "For more types have a look at https://www.hetzner.de/cloud"
  default     = "cx11"
}

variable "ssh_private_key" {
  description = "Private Key to access the machines"
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_public_key" {
  description = "Public Key to authorized the access for the machines"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "docker_version" {
  default = "17.03"
}

variable "kubernetes_version" {
  default = "1.11.2"
}

variable "core_dns" {
  default = "false"
}

variable "dns_zone" {
  type = "string"
}

variable "oidc_client_id" {}
variable "oidc_issuer_url" {}
variable "oidc_username_claim" {}

variable "master_count" {}
variable "ingress_count" {}
variable "worker_count" {}

variable "acme_registration_email_address" {}
variable "acme_provider" {}

variable acme_server_url {
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
