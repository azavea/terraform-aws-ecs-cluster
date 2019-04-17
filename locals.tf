locals {
  cluster_name = "ecs${title(var.environment)}Cluster"
  asg_name     = "asg${title(var.environment)}ContainerInstance"
  sg_name      = "sgContainerInstance"
}
