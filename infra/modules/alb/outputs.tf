output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "ALB DNS name — set as CloudFront origin or in Route 53"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID — needed for Route 53 alias records"
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "Attach this SG to all ECS EC2 instances — allows inbound from ALB only"
  value       = aws_security_group.ecs_tasks.id
}

output "target_group_arns" {
  description = "Map of service name → target group ARN — pass to ecs-service modules"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  value = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}
