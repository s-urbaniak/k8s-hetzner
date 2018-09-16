#!/bin/bash
set -eu
DOCKER_VERSION=${DOCKER_VERSION:-}
KUBERNETES_VERSION=${KUBERNETES_VERSION:-}
DOMAINS=${DOMAINS:-}

echo "
Package: docker-ce
Pin: version ${DOCKER_VERSION}.*
Pin-Priority: 1000
" > /etc/apt/preferences.d/docker-ce

sleep 30

apt-get -qq update
apt-get -qq install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get -qq update && apt-get -qq install -y docker-ce

cat > /etc/docker/daemon.json <<EOF
{
  "storage-driver":"overlay2" 
}
EOF

mkdir -p /etc/systemd/network
cat >/etc/systemd/network/eth0.network <<EOF
[Match]
Name=eth0

[Network]
DHCP=ipv4
Domains=${DOMAINS}
LinkLocalAddressing=ipv4
EOF

systemctl restart docker.service systemd-networkd

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

echo "
Package: kubelet
Pin: version ${KUBERNETES_VERSION}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubelet

echo "
Package: kubeadm
Pin: version ${KUBERNETES_VERSION}-*
Pin-Priority: 1000
" > /etc/apt/preferences.d/kubeadm

apt-get -qq update
apt-get -qq install -y kubelet kubeadm

mv -v /root/etc_default_kubelet /etc/default/kubelet 

systemctl daemon-reload
systemctl restart kubelet
