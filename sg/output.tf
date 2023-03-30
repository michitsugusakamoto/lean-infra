output "alb_sg" {
    value = aws_security_group.alb.id
}

output "ecs_task_sg" {
      value = aws_security_group.ecs_task.id
}

output "vpc_endpoint_sg" {
  value = aws_security_group.vpc_endpoint.id
}

output "rds_sg" {
  value = aws_security_group.rds.id
}