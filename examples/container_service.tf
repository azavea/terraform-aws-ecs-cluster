module "container_service_cluster" {
  source = "../"

  vpc_id            = "vpc-7e3f2618"
  lookup_latest_ami = true
  instance_type     = "t3.large"
  key_name          = "joker"

  cloud_config_content = templatefile("${path.module}/cloud-config/container-instance.yml.tmpl", {
    environment = "Joker"
  })

  root_block_device_type = "gp2"
  root_block_device_size = 30

  health_check_grace_period = 600
  min_size                  = 0
  max_size                  = 1

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  subnet_ids = ["subnet-b2f915e8"]

  project     = "Something"
  environment = "Joker"
}

resource "aws_security_group_rule" "container_instance_http_egress" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = module.container_service_cluster.container_instance_security_group_id
}

resource "aws_security_group_rule" "container_instance_https_egress" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = module.container_service_cluster.container_instance_security_group_id
}

resource "aws_autoscaling_policy" "container_instance_cpu_reservation" {
  name                   = "asgScalingPolicyCPUReservation"
  autoscaling_group_name = module.container_service_cluster.container_instance_autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = module.container_service_cluster.name
      }

      metric_name = "CPUReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }

    target_value = 50.0
  }
}

resource "aws_autoscaling_policy" "container_instance_memory_reservation" {
  name                   = "asgScalingPolicyMemoryReservation"
  autoscaling_group_name = module.container_service_cluster.container_instance_autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = module.container_service_cluster.name
      }

      metric_name = "MemoryReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }

    target_value = 90.0
  }
}
