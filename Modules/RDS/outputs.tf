output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = aws_db_instance.db_instance.id
}

output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.db_instance.endpoint
}

output "db_instance_address" {
  value = aws_db_instance.db_instance.address
}

output "db_instance_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.db_instance.port
}
output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.db_instance.arn
}
output "db_username" {
  description = "The username for the RDS instance"
  value       = aws_db_instance.db_instance.username
}