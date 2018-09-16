output "worker_ips" {
  value = ["${hcloud_server.worker.*.ipv4_address}"]
}

output "ingress_ips" {
  value = ["${hcloud_server.ingress.*.ipv4_address}"]
}

output "master_ips" {
  value = ["${hcloud_server.master.*.ipv4_address}"]
}

output "api_record" {
  value = "${cloudflare_record.api.*.hostname[0]}"
}

output "ingress_records" {
  value = "${cloudflare_record.ingress.*.hostname}"
}
