resource "hcloud_ssh_key" "k8s_admin" {
  name       = "k8s_admin"
  public_key = "${file(var.ssh_public_key)}"
}

data "template_file" "kubeadm_config_yaml" {
  template = "${file("${path.module}/kubeadm/config.yaml")}"

  vars {
    oidc_client_id            = "${var.oidc_client_id}"
    oidc_issuer_url           = "${var.oidc_issuer_url}"
    oidc_username_claim       = "${var.oidc_username_claim}"
    kubernetes_version        = "${var.kubernetes_version}"
    coredns_enabled           = "true"
    api_controlplane_endpoint = "api.${var.dns_zone}"
  }
}

data "template_file" "master_kubelet_conf" {
  template = "${file("${path.module}/default/kubelet")}"

  vars {
    node_labels = "node-role.kubernetes.io/master="
  }
}

resource "hcloud_server" "master" {
  count       = "${var.master_count}"
  name        = "master-${count.index}.${var.dns_zone}"
  server_type = "${var.master_type}"
  image       = "${var.node_image}"
  ssh_keys    = ["${hcloud_ssh_key.k8s_admin.id}"]

  connection {
    private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "file" {
    content     = "${data.template_file.kubeadm_config_yaml.rendered}"
    destination = "/etc/kubeadm.yaml"
  }

  provisioner "file" {
    content     = "${data.template_file.master_kubelet_conf.rendered}"
    destination = "/root/etc_default_kubelet"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = <<EOF
DOCKER_VERSION=${var.docker_version} \
KUBERNETES_VERSION=${var.kubernetes_version} \
DOMAINS=${var.dns_zone} \
/bin/bash /root/bootstrap.sh
EOF
  }
}

// after creating the master, allow other modules initialize.
//
// concretely:
// - let workers to be created in parallel
// - let Cloudflare DNS records be created
resource "null_resource" "master" {
  count = "${var.master_count}"

  connection {
    host        = "${hcloud_server.master.*.ipv4_address[count.index]}"
    private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/master.sh"
    destination = "/root/master.sh"
  }

  provisioner "remote-exec" {
    inline = "CORE_DNS=${var.core_dns} bash /root/master.sh"
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/copy-kubeadm-token.sh"

    environment {
      SSH_PRIVATE_KEY = "${var.ssh_private_key}"
      SSH_USERNAME    = "root"
      SSH_HOST        = "${hcloud_server.master.ipv4_address}"
      TARGET          = "secrets/"
    }
  }
}
