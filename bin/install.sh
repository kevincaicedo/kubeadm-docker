#!/bin/bash



# ----------------------------- # 
# ---------- Step 1 ----------- #
# ---------- Docker ----------- #
# ----------------------------- #

yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum update -y
yum install -y docker-ce

systemctl enable docker
mkdir /etc/docker
cp ../setup/daemon.json /etc/docker/
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload && systemctl restart docker && systemctl enable docker




# ----------------------------- # 
# ---------- Step 1 ----------- #
# -------- Kubernetes --------- #
# ----------------------------- #
update-alternatives --set iptables /usr/sbin/iptables-legacy
swapoff -a

cp ../repo/kubernetes.repo /etc/yum.repos.d/
setenforce 0 && sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
yum update -y && yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
cp ../setup/k8s.conf /etc/sysctl.d/
sysctl --system
modprobe br_netfilter
cp ../setup/kubelet /etc/default/kubelet
systemctl daemon-reload && systemctl restart kubelet
systemctl enable kubelet

if [ "$1" = "master" ];
then
    kubeadm init --pod-network-cidr=192.168.0.0/16
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/calico.yaml
fi