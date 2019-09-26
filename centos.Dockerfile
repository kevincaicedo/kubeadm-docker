FROM centos/systemd

LABEL mantainer="kcaicedo@coopebombas.com"
LABEL version="1.0"
LABEL name="k8s-docker"

# Install Docker

RUN yum install -y yum-utils device-mapper-persistent-data lvm2

RUN yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo

RUN yum update -y

RUN yum install -y docker-ce-18.06.2.ce

RUN systemctl enable docker

VOLUME [ "/var/lib/docker/" ]

RUN mkdir /etc/docker

ADD setup/daemon.json /etc/docker/

RUN mkdir -p /etc/systemd/system/docker.service.d

RUN exec bash && systemctl daemon-reload

RUN exec bash && systemctl restart docker

RUN exec bash && systemctl enable docker

RUN exec bash && hostnamectl set-hostname 'k8s-master'

RUN exec bash && setenforce 0 && sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux


# Install Kubernetes

RUN exec bash && update-alternatives --set iptables /usr/sbin/iptables-legacy

RUN exec bash && swapoff -a

ADD repo/kubernetes.repo /etc/yum.repos.d/

RUN exec bash && setenforce 0

RUN exec bash && sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

RUN yum update -y && yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

RUN exec bash && systemctl enable --now kubelet

ADD setup/k8s.conf /etc/sysctl.d/

RUN exec bash && sysctl --system

RUN exec bash && modprobe br_netfilter

ADD setup/kubelet /etc/default/kubelet

RUN exec bash && systemctl daemon-reload && systemctl restart kubelet