resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.vpc_security_group_ids
  iam_instance_profile   = "SSMRoleForEC2"
  user_data              = <<-EOT
#!/bin/bash

# Exit on error
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1

# hostname 설정
PRIVATE_IP=$(hostname -i)
hostnamectl set-hostname k8s-master

# Get the private IP address
echo "$PRIVATE_IP k8s-master" >> /etc/hosts

# Swap 비활성화 (한 번만 실행)
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

# Containerd 설치 및 설정
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# Kubernetes 저장소 추가
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

# Kubernetes 설치
apt-get update
apt-get install -y kubelet kubeadm kubectl bash-completion
apt-mark hold kubelet kubeadm kubectl

# kubelet 활성화
systemctl enable --now kubelet

# kubernetes 초기화
kubeadm init \
  --apiserver-advertise-address="$PRIVATE_IP" \
  --pod-network-cidr=10.244.0.0/16 \
  --upload-certs \
  --ignore-preflight-errors=NumCPU \
  --node-name k8s-master

# kubeadm init 완료 대기
while [ ! -f /etc/kubernetes/admin.conf ]; do
    echo "Waiting for admin.conf to be created..."
    sleep 5
done

# 조인 토큰 저장
kubeadm token create --print-join-command > /var/log/kubeadm-join-command.txt

# kubectl 설정
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Flannel 네트워크 설치
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml --validate=false

# 모든 사용자를 위한 kubectl 설정
sudo tee /etc/profile.d/k8s-completion.sh > /dev/null << 'EOF'
# Kubectl 자동완성 설정
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF

chmod +x /etc/profile.d/k8s-completion.sh

source /etc/profile.d/k8s-completion.sh

# helm 설치
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

EOT

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-master-ec2"
  }
}

resource "null_resource" "check_user_data_log" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = "aws ssm start-session --target ${aws_instance.master.id} --document-name AWS-StartInteractiveCommand --parameters command='sudo cat /var/log/user-data.log'"
  }
}