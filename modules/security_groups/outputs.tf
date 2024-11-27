output "master_sg_id" {
  value       = aws_security_group.master_sg.id
  description = "The security group ID for the Kubernetes Master Node"
}

output "worker_sg_id" {
  value       = aws_security_group.worker_sg.id
  description = "The security group ID for the Kubernetes Worker Nodes"
}