# 마스터 노드 보안 그룹
resource "aws_security_group" "master_sg" {
  name_prefix = "${var.project_name}-k8s-master-sg-"
  description = "Security group for Kubernetes Master Node"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  }

  ingress {
    description = "Allow Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow etcd server client API"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow Kubelet API on control plane"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-k8s-master-sg"
  }
}

# 워커 노드 보안 그룹
resource "aws_security_group" "worker_sg" {
  name_prefix = "${var.project_name}-k8s-worker-sg-"
  description = "Security group for Kubernetes Worker Nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH from current IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.body)}/32"]
  }

  ingress {
    description = "Allow Kubelet API on worker nodes"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow NodePort services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-k8s-worker-sg"
  }
}

# 현재 사용자 IP를 가져오는 데이터 소스
data "http" "my_ip" {
  url = "http://checkip.amazonaws.com/"
}