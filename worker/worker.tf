resource "aws_instance" "worker" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnets[count.index]
  vpc_security_group_ids = var.vpc_security_group_ids
  iam_instance_profile   = "SSMRoleForEC2"
  user_data              = <<-EOT
#!/bin/bash

# Exit on error
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1

# hostname 설정
hostnamectl set-hostname k8s-worker-${count.index + 1}
echo "127.0.0.1 k8s-worker-${count.index + 1}" >> /etc/hosts

# Swap 비활성화
swapoff -a
sed -i '/swap/d' /etc/fstab

# 커널 모듈 활성화
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 필요한 sysctl 파라미터 설정
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 기본 설치
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# Kubernetes 저장소 추가
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' > /etc/apt/sources.list.d/kubernetes.list

# Kubernetes 설치
apt-get update
apt-get install -y kubelet kubeadm kubectl bash-completion containerd
apt-mark hold kubelet kubeadm kubectl

# containerd 설정
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# kubelet 활성화
systemctl enable --now kubelet

# 모든 사용자를 위한 kubectl 설정
sudo tee /etc/profile.d/k8s-completion.sh > /dev/null << 'EOF'
# Kubectl 자동완성 설정
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF

chmod +x /etc/profile.d/k8s-completion.sh

source /etc/profile.d/k8s-completion.sh

# 필요한 디렉토리 생성
mkdir -p /etc/kubernetes/manifests
mkdir -p /var/lib/kubelet

EOT

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-worker-${count.index + 1}-ec2"
  }

}