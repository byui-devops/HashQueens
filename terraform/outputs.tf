output "ecr_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}
