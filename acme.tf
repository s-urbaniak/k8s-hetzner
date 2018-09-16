provider "acme" {
  server_url = "${var.acme_server_url}"
}

resource "tls_private_key" "acme_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.acme_private_key.private_key_pem}"
  email_address   = "${var.acme_registration_email_address}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "sur.host"
  subject_alternative_names = ["www.sur.host"]

  dns_challenge {
    provider = "${var.acme_provider}"
  }
}

resource "local_file" "ingress_secrets" {
  filename = "manifests/ingress-secret.json"

  content = <<EOF
apiVersion: v1
data:
  tls.crt: ${base64encode(acme_certificate.certificate.certificate_pem)}
  tls.key: ${base64encode(acme_certificate.certificate.private_key_pem)}
kind: Secret
metadata:
  name: ingress
  namespace: kube-system
type: Opaque
EOF
}
