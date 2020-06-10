output "id" {
  value       = aws_ecs_cluster.container_instance.id
  description = "The container service cluster ID"
}

output "name" {
  value       = aws_ecs_cluster.container_instance.name
  description = "The container service cluster name"
}

output "container_instance_security_group_id" {
  value       = aws_security_group.container_instance.id
  description = "Security group ID of the EC2 container instances"
}

output "container_instance_ecs_for_ec2_service_role_name" {
  value       = aws_iam_role.container_instance_ec2.name
  description = "Name of IAM role associated with EC2 container instances"
}

output "ecs_service_role_name" {
  value       = aws_iam_role.ecs_service_role.name
  description = "Name of IAM role for use with ECS services"
}

output "container_instance_autoscaling_group_name" {
  value       = aws_autoscaling_group.container_instance.name
  description = "Name of container instance Auto Scaling Group"
}

output "ecs_service_role_arn" {
  value       = aws_iam_role.ecs_service_role.arn
  description = "ARN of IAM role for use with ECS services"
}

output "container_instance_ecs_for_ec2_service_role_arn" {
  value       = aws_iam_role.container_instance_ec2.arn
  description = "ARN of IAM role associated with EC2 container instances"
}
