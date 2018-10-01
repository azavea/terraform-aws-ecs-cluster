#
# Container Instance IAM resources
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
# ECS Service IAM permissions
#

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name               = "ecs${title(var.environment)}ServiceRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_service_role" {
  role       = "${aws_iam_role.ecs_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_iam_policy_document" "ecs_autoscale_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
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
    content_type = "${var.cloud_config_content_type}"
    content      = "${var.cloud_config_content}"
  }
}

data "aws_ami" "ecs_ami" {
  count       = "${var.lookup_latest_ami ? 1 : 0}"
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }

  filter {
    name   = "owner-alias"
    values = ["${var.ami_owners}"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "user_ami" {
  count  = "${var.lookup_latest_ami ? 0 : 1}"
  owners = ["${var.ami_owners}"]

  filter {
    name   = "image-id"
    values = ["${var.ami_id}"]
  }
}

resource "aws_launch_template" "container_instance" {
  block_device_mappings {
    device_name = "${var.lookup_latest_ami ? join("", data.aws_ami.ecs_ami.*.root_device_name) : join("", data.aws_ami.user_ami.*.root_device_name)}"

    ebs {
      volume_type = "${var.root_block_device_type}"
      volume_size = "${var.root_block_device_size}"
    }
  }

  credit_specification {
    cpu_credits = "${var.cpu_credit_specification}"
  }

  disable_api_termination = false

  name_prefix = "lt${title(var.environment)}ContainerInstance-"

  iam_instance_profile {
    name = "${aws_iam_instance_profile.container_instance.name}"
  }

  # Using join() is a workaround for depending on conditional resources.
  # https://github.com/hashicorp/terraform/issues/2831#issuecomment-298751019
  image_id = "${var.lookup_latest_ami ? join("", data.aws_ami.ecs_ami.*.image_id) : join("", data.aws_ami.user_ami.*.image_id)}"

  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = "${var.instance_type}"
  key_name                             = "${var.key_name}"
  vpc_security_group_ids               = ["${aws_security_group.container_instance.id}"]
  user_data                            = "${base64encode(data.template_cloudinit_config.container_instance_cloud_config.rendered)}"

  monitoring {
    enabled = "${var.detailed_monitoring}"
  }
}

resource "aws_autoscaling_group" "container_instance" {
  lifecycle {
    create_before_destroy = true
  }

  name = "asg${title(var.environment)}ContainerInstance"

  launch_template = {
    id      = "${aws_launch_template.container_instance.id}"
    version = "$$Latest"
  }

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
  name = "ecs${title(var.environment)}Cluster"
}

#
# CloudWatch resources
#
resource "aws_autoscaling_policy" "container_instance_scale_up" {
  name                   = "asgScalingPolicy${title(var.environment)}ClusterScaleUp"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_up_cooldown_seconds}"
  autoscaling_group_name = "${aws_autoscaling_group.container_instance.name}"
}

resource "aws_autoscaling_policy" "container_instance_scale_down" {
  name                   = "asgScalingPolicy${title(var.environment)}ClusterScaleDown"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = "${var.scale_down_cooldown_seconds}"
  autoscaling_group_name = "${aws_autoscaling_group.container_instance.name}"
}

resource "aws_cloudwatch_metric_alarm" "container_instance_high_cpu" {
  alarm_name          = "alarm${title(var.environment)}ClusterCPUReservationHigh"
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

  alarm_description = "Scale up if CPUReservation is above N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_low_cpu" {
  alarm_name          = "alarm${title(var.environment)}ClusterCPUReservationLow"
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

  alarm_description = "Scale down if the CPUReservation is below N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_down.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_high_cpu"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_high_memory" {
  alarm_name          = "alarm${title(var.environment)}ClusterMemoryReservationHigh"
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

  alarm_description = "Scale up if the MemoryReservation is above N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_up.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_low_cpu"]
}

resource "aws_cloudwatch_metric_alarm" "container_instance_low_memory" {
  alarm_name          = "alarm${title(var.environment)}ClusterMemoryReservationLow"
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

  alarm_description = "Scale down if the MemoryReservation is below N% for N duration"
  alarm_actions     = ["${aws_autoscaling_policy.container_instance_scale_down.arn}"]

  depends_on = ["aws_cloudwatch_metric_alarm.container_instance_high_memory"]
}
