#!/bin/bash

echo "Preparing node for kubernetes bootstrap"

echo "Disabling swap..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "Disabling SElinux"
setenforce 0
sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

echo "Adding docker repo.."
curl https://download.docker.com/linux/rhel/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
ls /etc/yum.repos.d/docker-ce.repo


echo "Installing containerd"

dnf install containerd.io-2.2.2 -y


echo "Configuring containerd..."

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

echo "Starting containerd.."
systemctl enable --now containerd.service

echo "Enabling IPv4 forwarding..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/98-k8s.conf
sysctl --system

echo "Add Kubernetes repo"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "Installing kubelet, kubeadm, and kubectl..."
dnf install -y kubelet kubeadm kubectl --setopt=disable_excludes=kubernetes

echo "Enabling kubelet service"
systemctl enable kubelet.service

echo "Stopping firewalld"
systemctl disable firewalld.service
systemctl stop firewalld.service

echo "Preparation complete."