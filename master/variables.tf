variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "project_name" {}
variable "vpc_security_group_ids" {
  type        = list(string)
  description = "List of security group IDs for the master node"
}
