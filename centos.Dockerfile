FROM centos/systemd

LABEL mantainer="kcaicedo@coopebombas.com"
LABEL version="1.0"
LABEL name="k8s-docker"

# Install Docker

RUN yum install -y yum-utils device-mapper-persistent-data lvm2

RUN yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo

RUN yum update -y

RUN yum install -y docker-ce

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

ADD repo/kubernetes.repo /etc/yum.repos.d/

RUN yum update -y && yum install -y kubelet kubeadm kubectl && yum clean all

ADD setup/kubelet /etc/default/kubelet

RUN systemctl enable kubelet

RUN exec bash && systemctl enable kubelet &&  systemctl start kubelet

RUN exec bash && update-alternatives --set iptables /usr/sbin/iptables-legacy

ADD setup/k8s.conf /etc/sysctl.d/

RUN exec bash && sysctl --system

RUN exec bash && modprobe br_netfilter

RUN exec bash && echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

RUN exec bash && systemctl daemon-reload && systemctl restart kubelet

# ADD repo/kubernetes.repo /etc/yum.repos.d/

# RUN yum update -y && yum install -y kubelet kubeadm kubectl && yum clean all

# RUN systemctl enable kubelet

# RUN exec bash && systemctl enable kubelet &&  systemctl start kubelet

# RUN update-alternatives --set iptables /usr/sbin/iptables-legacy