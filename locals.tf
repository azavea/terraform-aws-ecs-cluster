locals {
  cluster_name                  = "ecs${title(var.environment)}Cluster"
  autoscaling_group_name        = "asg${title(var.environment)}ContainerInstance"
  security_group_name           = "sgContainerInstance"
  ecs_for_ec2_service_role_name = "${var.environment}ContainerInstanceProfile"
  ecs_service_role_name         = "ecs${title(var.environment)}ServiceRole"

  root_device = {
    device_name = "${var.lookup_latest_ami ? join("", data.aws_ami.ecs_ami.*.root_device_name) : join("", data.aws_ami.user_ami.*.root_device_name)}"

    ebs = [{
      volume_type = "${var.root_block_device_type}"
      volume_size = "${var.root_block_device_size}"
    }]
  }

  data_device = {
    device_name = "${var.data_block_device_name}"

    ebs = [{
      volume_type = "${var.data_block_device_type}"
      volume_size = "${var.data_block_device_size}"
      delete_on_termination = "${var.data_block_device_delete_on_termination}"
    }]
  }

  volume_devices_without_data = [
    "${local.root_device}",
  ]

  volume_devices_with_data = [
    "${local.root_device}",
    "${local.data_device}",
  ]

  //  https://github.com/hashicorp/terraform/issues/12453#issuecomment-311611817
  volume_end_index = "${var.enable_data_block_device ? 2 : 1}"
  volume_devices = "${slice(local.volume_devices_with_data, 0, local.volume_end_index)}"
}
