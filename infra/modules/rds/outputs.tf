output "endpoint" {
  description = "RDS endpoint hostname — use in DATABASE_URL"
  value       = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "instance_id" {
  description = "RDS instance identifier — use with aws rds stop-db-instance to pause in dev"
  value       = aws_db_instance.this.identifier
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
