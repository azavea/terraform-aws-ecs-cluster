# terraform-aws-ecs-cluster

[![CircleCI](https://circleci.com/gh/azavea/terraform-aws-ecs-cluster.svg?style=svg)](https://circleci.com/gh/azavea/terraform-aws-ecs-cluster)

A Terraform module to create an Amazon Web Services (AWS) EC2 Container Service (ECS) cluster.

## Table of Contents

* [Usage](#usage)
    * [Auto Scaling](#auto-scaling)
* [Variables](#variables)
* [Outputs](#outputs)

## Usage

This module creates a security group that gets associated with the launch template for the ECS cluster Auto Scaling group. By default, the security group contains no rules. In order for network traffic to flow egress or ingress (including communication with ECS itself), you must associate all of the appropriate `aws_security_group_rule` resources with the `container_instance_security_group_id` module output.

See below for an example.

```hcl
data "template_file" "container_instance_cloud_config" {
  template = "${file("cloud-config/container-instance.yml.tpl")}"

  vars {
    environment = "${var.environment}"
  }
}

module "container_service_cluster" {
  source = "github.com/azavea/terraform-aws-ecs-cluster?ref=3.0.0"

  vpc_id        = "vpc-20f74844"
  ami_id        = "ami-b2df2ca4"
  instance_type = "t2.micro"
  key_name      = "hector"
  cloud_config_content  = "${data.template_file.container_instance_cloud_config.rendered}"

  root_block_device_type = "gp2"
  root_block_device_size = "10"

  health_check_grace_period = "600"
  desired_capacity          = "1"
  min_size                  = "0"
  max_size                  = "1"

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

  subnet_ids = [...]

  project     = "Something"
  environment = "Staging"
}

resource "aws_security_group_rule" "container_instance_http_egress" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${module.container_service_cluster.container_instance_security_group_id}"
}

resource "aws_security_group_rule" "container_instance_https_egress" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${module.container_service_cluster.container_instance_security_group_id}"
}
```

### Auto Scaling

This module creates an Auto Scaling group for the ECS cluster. By default, there are no Auto Scaling policies associated with this group. In order for Auto Scaling to function, you must define `aws_autoscaling_policy` resources and associate them with the `container_instance_autoscaling_group_name` module output.

See this [article](https://segment.com/blog/when-aws-autoscale-doesn-t/) for more information on Auto Scaling, and below for example policies.

```hcl
resource "aws_autoscaling_policy" "container_instance_cpu_reservation" {
  name                   = "asgScalingPolicyCPUReservation"
  autoscaling_group_name = "${module.container_service_cluster.container_instance_autoscaling_group_name}"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = "${module.container_service_cluster.name}"
      }

      metric_name = "CPUReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }

    target_value = "50.0"
  }
}

resource "aws_autoscaling_policy" "container_instance_memory_reservation" {
  name                   = "asgScalingPolicyMemoryReservation"
  autoscaling_group_name = "${module.container_service_cluster.container_instance_autoscaling_group_name}"
  adjustment_type        = "ChangeInCapacity"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = "${module.container_service_cluster.name}"
      }

      metric_name = "MemoryReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }

    target_value = "90.0"
  }
}
```

It's worth noting that the [`aws_autoscaling_policy`](https://www.terraform.io/docs/providers/aws/r/autoscaling_policy.html) documentation suggests we remove `desired_capacity` from the `aws_autoscaling_group` resource when using Auto Scaling. That makes sense, because when it is present, any Terraform plan/apply cycle will reset it.

Unfortunately, removing it from the `aws_autoscaling_group` resource means removing it from the module too.

We will reevaluate things when [Terraform 0.12](https://www.hashicorp.com/blog/terraform-0-12-conditional-operator-improvements) comes out because it promises handling of a `null` `desired_capacity`.

## Variables

- `cluster_name` - Name of the ECS Cluster, it is optional
- `autoscaling_group_name` - Name of the autoscaling group for ECS Cluster, it is optional
- `security_group_name` - Name of the security group for ECS Cluster, it is optional
- `ecs_for_ec2_service_role_name` - Name of iam role for ECS Cluster, it is optional
- `ecs_service_role_name` - Name of iam role for ECS Service, it is optional
- `vpc_id` - ID of VPC meant to house cluster
- `lookup_latest_ami` - lookup the latest Amazon-owned ECS AMI. If this variable is `true`, the latest ECS AMI will be used, even if `ami_id` is provided (default: `false`).
- `ami_id` - Cluster instance Amazon Machine Image (AMI) ID. If `lookup_latest_ami` is `true`, this variable will be silently ignored.
- `ami_owners` - List of accounts that own the AMI (default: `self, amazon, aws-marketplace`)
- `root_block_device_type` - Instance root block device type (default: `gp2`)
- `root_block_device_size` - Instance root block device size in gigabytes (default: `8`)
- `instance_type` - Instance type for cluster instances (default: `t2.micro`)
- `cpu_credit_specification` - Credit option for CPU usage. Can be ["standard"](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-standard-mode.html) or ["unlimited"](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances-unlimited-mode.html). (default: `standard`).
- `detailed_monitoring` - If this variable is `true`, then [detailed monitoring](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-cloudwatch-new.html) will be enabled on the instance. (default: `false`)
- `key_name` - EC2 Key pair name
- `cloud_config_content` - user data supplied to launch configuration for cluster nodes
- `cloud_config_content_type` - the type of configuration being passed in as user data, see [EC2 user guide](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonLinuxAMIBasics.html#CloudInit) for a list of possible types (default: `text/cloud-config`)
- `health_check_grace_period` - Time in seconds after container instance comes into service before checking health (default: `600`)
- `desired_capacity` - Number of EC2 instances that should be running in cluster (default: `1`)
- `min_size` - Minimum number of EC2 instances in cluster (default: `0`)
- `max_size` - Maximum number of EC2 instances in cluster (default: `1`)
- `enabled_metrics` - A list of metrics to gather for the cluster
- `subnet_ids` - A list of subnet IDs to launch cluster instances
- `project` - Name of project this cluster is for (default: `Unknown`)
- `environment` - Name of environment this cluster is targeting (default: `Unknown`)

## Outputs

- `id` - The container service cluster ID
- `name` - The container service cluster name
- `container_instance_security_group_id` - Security group ID of the EC2 container instances
- `container_instance_ecs_for_ec2_service_role_name` - Name of IAM role associated with EC2 container instances
- `ecs_service_role_name` - Name of IAM role for use with ECS services
- `ecs_service_role_arn` - ARN of IAM role for use with ECS services
- `container_instance_ecs_for_ec2_service_role_arn` - ARN of IAM role associated with EC2 container instances
- `container_instance_autoscaling_group_name` - Name of container instance Auto Scaling Group
