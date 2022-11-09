locals {
  cluster_name                  = "ecs${title(var.environment)}Cluster"
  autoscaling_group_name        = "asg${title(var.environment)}ContainerInstance"
  security_group_name           = "sgContainerInstance"
  ecs_for_ec2_service_role_name = "${var.environment}ContainerInstanceProfile"
  ecs_service_role_name         = "ecs${title(var.environment)}ServiceRole"
}

