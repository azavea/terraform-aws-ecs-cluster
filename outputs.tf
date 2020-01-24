output "id" {
  value = aws_ecs_cluster.container_instance.id
}

output "name" {
  value = aws_ecs_cluster.container_instance.name
}

output "container_instance_security_group_ids" {
  value = aws_security_group.container_instance[*].id
}

output "container_instance_ecs_for_ec2_service_role" {
  value = {
    for role in aws_iam_role.container_instance_ec2 :
    role.name => {
      name = role.name
      id   = role.id
    }
  }
}

output "ecs_service_role_name" {
  value = aws_iam_role.ecs_service_role.name
}

output "container_instance_autoscaling_group" {
  value = {
    for asg in aws_autoscaling_group.container_instance :
    "name" => asg.name
  }
}

output "ecs_service_role_arn" {
  value = aws_iam_role.ecs_service_role.arn
}
