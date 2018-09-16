resource "cloudflare_record" "ingress" {
  count = "${var.ingress_count}"
  name  = "${var.dns_zone}"

  domain = "${var.dns_zone}"
  value  = "${hcloud_server.ingress.*.ipv4_address[count.index]}"
  type   = "A"
  ttl    = 120

  proxied = false
}

resource "cloudflare_record" "api" {
  name  = "api.${var.dns_zone}"
  count = "${var.master_count}"

  domain = "${var.dns_zone}"
  value  = "${hcloud_server.master.*.ipv4_address[count.index]}"
  type   = "A"
  ttl    = 120

  proxied = false
}

resource "cloudflare_record" "master" {
  name  = "master-${count.index}.${var.dns_zone}"
  count = "${var.master_count}"

  domain = "${var.dns_zone}"
  value  = "${hcloud_server.master.*.ipv4_address[count.index]}"
  type   = "A"
  ttl    = 120

  proxied = false
}

resource "cloudflare_record" "worker" {
  name  = "worker-${count.index}.${var.dns_zone}"
  count = "${var.worker_count}"

  domain = "${var.dns_zone}"
  value  = "${hcloud_server.worker.*.ipv4_address[count.index]}"
  type   = "A"
  ttl    = 120

  proxied = false
}

resource "cloudflare_record" "ingress_nodes" {
  name  = "ingress-${count.index}.${var.dns_zone}"
  count = "${var.ingress_count}"

  domain = "${var.dns_zone}"
  value  = "${hcloud_server.ingress.*.ipv4_address[count.index]}"
  type   = "A"
  ttl    = 120

  proxied = false
}
