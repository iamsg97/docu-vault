output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "task_execution_role_arn" {
  description = "Execution role ARN — attach to every task definition for ECR + CWLogs access"
  value       = aws_iam_role.task_execution.arn
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.this.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.ecs.name
}
