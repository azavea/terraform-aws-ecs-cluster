#
# IAM resources
#
data "aws_iam_policy_document" "container_instance_ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "container_instance_ec2" {
  name               = "${var.environment}ContainerInstanceProfile"
  assume_role_policy = "${data.aws_iam_policy_document.container_instance_ec2_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ec2_service_role" {
  role       = "${aws_iam_role.container_instance_ec2.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "container_instance" {
  name = "${aws_iam_role.container_instance_ec2.name}"
  role = "${aws_iam_role.container_instance_ec2.name}"
}

#
# Security group resources
#
resource "aws_security_group" "container_instance" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "sgContainerInstance"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

#
# AutoScaling resources
#
data "template_file" "container_instance_base_cloud_config" {
  template = "${file("${path.module}/cloud-config/base-container-instance.yml.tpl")}"

  vars {
    ecs_cluster_name = "${aws_ecs_cluster.container_instance.name}"
  }
}

data "template_cloudinit_config" "container_instance_cloud_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content      = "${data.template_file.container_instance_base_cloud_config.rendered}"
  }

  part {
    content_type = "text/cloud-config"
    content      = "${var.cloud_config}"
  }
}

resource "aws_launch_configuration" "container_instance" {
  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile = "${aws_iam_instance_profile.container_instance.name}"
  image_id             = "${var.ami_id}"
  instance_type        = "${var.instance_type}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.container_instance.id}"]
  user_data            = "${data.template_cloudinit_config.container_instance_cloud_config.rendered}"
}

resource "aws_autoscaling_group" "container_instance" {
  name                      = "asg${var.environment}ContainerInstance"
  launch_configuration      = "${aws_launch_configuration.container_instance.name}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type         = "EC2"
  desired_capacity          = "${var.desired_capacity}"
  termination_policies      = ["OldestLaunchConfiguration", "Default"]
  min_size                  = "${var.min_size}"
  max_size                  = "${var.max_size}"
  enabled_metrics           = ["${var.enabled_metrics}"]
  vpc_zone_identifier       = ["${var.private_subnet_ids}"]

  tag {
    key                 = "Name"
    value               = "ContainerInstance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "${var.project}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}

#
# ECS resources
#
resource "aws_ecs_cluster" "container_instance" {
  name = "ecs${var.environment}Cluster"
}

#
# CloudWatch resources
#
resource "aws_autoscaling_policy" "container_instance_scale_up" {
  name                   = "asgScalingPolicy${var.environment}ClusterScaleUp"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_up_cooldown_seconds}"
  autoscaling_group_name = "${aws_autoscaling_group.container_instance.name}"
}

resource "aws_autoscaling_policy" "container_instance_scale_down" {
  name                   = "asgScalingPolicy${var.environment}ClusterScaleDown"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_down_cooldown_seconds}"
  autoscaling_group_name = "${aws_autoscaling_group.container_instance.name}"
}

resource "aws_cloudwatch_metric_alarm" "container_instance_high_cpu" {
  alarm_name          = "alarm${var.environment}ClusterCPUReservationHigh"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.high_cpu_evaluation_periods}"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "${var.high_cpu_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.high_cpu_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale up if CPUReservation is above 90% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_low_cpu" {
  alarm_name          = "alarm${var.environment}ClusterCPUReservationLow"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.low_cpu_evaluation_periods}"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "${var.low_cpu_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.low_cpu_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale down if the CPUReservation is below 10% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_down.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_high_cpu"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_high_memory" {
  alarm_name          = "alarm${var.environment}ClusterMemoryReservationHigh"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.high_memory_evaluation_periods}"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "${var.high_memory_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.high_memory_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale up if the MemoryReservation is above 90% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_up.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_low_cpu"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_low_memory" {
  alarm_name          = "alarm${var.environment}ClusterMemoryReservationLow"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.low_memory_evaluation_periods}"
  metric_name         = "MemoryReservation"
  namespace           = "AWS/ECS"
  period              = "${var.low_memory_period_seconds}"
  statistic           = "Maximum"
  threshold           = "${var.low_memory_threshold_percent}"

  dimensions {
    ClusterName = "${aws_ecs_cluster.container_instance.name}"
  }

  alarm_description = "Scale down if the MemoryReservation is below 10% for 10 minutes"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_down.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_high_memory"]
}
