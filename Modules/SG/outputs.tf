output "externalalb_sgid" {
  description = "Security Group id for External Load Balancer"
  value       = aws_security_group.external_alb_sg.id
}

output "internalalb_sgid" {
  description = "Security Group id for Internal Load Balancer"
  value       = aws_security_group.internal_alb_sg.id
}

output "frontend_sgid" {
  description = "Security Group id for Frontend"
  value       = aws_security_group.frontend_sg.id
}

output "backend_sgid" {
  description = "Security Group id for Backend"
  value       = aws_security_group.backend_sg.id
}

output "db_sgid" {
  description = "Security Group id for Database"
  value       = aws_security_group.db_sg.id
}

output "bastion_host_sgid" {
  description = "Security Group id for Bastion Host"
  value       = aws_security_group.bastion_host_sg.id
}
