output "db_endpoint" {
  description = "RDS connection endpoint"
  value       = aws_db_instance.example.endpoint
  sensitive   = false
}

output "db_username" {
  description = "Database username"
  value       = aws_db_instance.example.username
  sensitive   = true
}

output "db_connection_string" {
  description = "Full connection string — marked sensitive"
  value       = "mysql://${aws_db_instance.example.username}@${aws_db_instance.example.endpoint}/appdb"
  sensitive   = true
}