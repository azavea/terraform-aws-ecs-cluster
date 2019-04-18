locals {
  cluster_name           = "ecs${title(var.environment)}Cluster"
  autoscaling_group_name = "asg${title(var.environment)}ContainerInstance"
  sg_name                = "sgContainerInstance"
  iam_role_name          = "${var.environment}ContainerInstanceProfile"
}
