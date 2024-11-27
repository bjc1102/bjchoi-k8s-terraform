variable "project_name" {
  default = "bjchoi-k8s"
}

variable "vpc_id" {
  default = "vpc-007f6f62fffdf5b23"
}

variable "subnets" {
  default = ["subnet-044a364a5a8b672e7", "subnet-0f2ea19aba9663c70"]
}

variable "ami_id" {
  default = "ami-040c33c6a51fd5d96"
}

variable "instance_type" {
  default = "t3.medium"
}