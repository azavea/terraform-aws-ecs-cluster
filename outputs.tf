output "id" {
  value = "${aws_ecs_cluster.container_instance.id}"
}

output "name" {
  value = "${aws_ecs_cluster.container_instance.name}"
}

output "container_instance_security_group_id" {
  value = "${aws_security_group.container_instance.id}"
}

output "container_instance_ecs_for_ec2_service_role" {
  value = "${aws_iam_role.container_instance_ec2.name}"
}
