data "template_file" "ingress_kubelet_conf" {
  template = "${file("${path.module}/default/kubelet")}"

  vars {
    node_labels = "node-role.kubernetes.io/ingress="
  }
}

resource "hcloud_server" "ingress" {
  count       = "${var.ingress_count}"
  name        = "ingress-${count.index}.${var.dns_zone}"
  server_type = "${var.ingress_type}"
  image       = "${var.node_image}"
  depends_on  = ["hcloud_server.master"]
  ssh_keys    = ["${hcloud_ssh_key.k8s_admin.id}"]

  connection {
    private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "file" {
    content     = "${data.template_file.ingress_kubelet_conf.rendered}"
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
/bin/sh /root/bootstrap.sh
EOF
  }

  provisioner "file" {
    source      = "secrets/kubeadm_join"
    destination = "/tmp/kubeadm_join"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = "${file(var.ssh_private_key)}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/node.sh"
    destination = "/root/node.sh"
  }

  provisioner "remote-exec" {
    inline = "bash /root/node.sh"
  }
}
