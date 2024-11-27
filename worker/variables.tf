variable "ami_id" {}
variable "instance_type" {}
variable "subnets" {}
variable "key_name" {}
variable "project_name" {}
variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for worker nodes"
}
variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/ㅠ" # 기본값 설정
}
