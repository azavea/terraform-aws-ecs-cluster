# terraform-aws-ecs-cluster

A Terraform module to create an Amazon Web Services (AWS) EC2 Container Service (ECS) cluster.

## Usage

```hcl
data "template_file" "container_instance_cloud_config" {
  template = "${file("cloud-config/container-instance.yml.tpl")}"
 
  vars {
    environment = "${var.environment}"
  }
}

module "container_service_cluster" {
  source = "github.com/azavea/terraform-aws-ecs-cluster?ref=0.1.0"

  vpc_id        = "vpc-20f74844"
  ami_id        = "ami-b2df2ca4"
  instance_type = "t2.micro"
  key_name      = "hector"
  cloud_config  = "${data.template_file.container_instance_cloud_config.rendered}"

  root_block_device_type = "gp2"
  root_block_device_size = "10

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

  private_subnet_ids = [...]

  project     = "Something"
  environment = "Staging"
}
```

## Variables

- `vpc_id` - ID of VPC meant to house cluster
- `ami_id` - Cluster instance Amazon Machine Image (AMI) ID
- `root_block_device_type` - Instance root block device type (default: `gp2`)
- `root_block_device_size` - Instance root block device size in gigabytes (default: `8`)
- `instance_type` - Instance type for cluster instances (default: `t2.micro`)
- `key_name` - EC2 Key pair name
- `cloud_config` - `cloud-config` user data supplied to launch configuration for cluster nodes
- `health_check_grace_period` - Time in seconds after container instance comes into service before checking health (default: `600`)
- `desired_capacity` - Number of EC2 instances that should be running in cluster (default: `1`)
- `min_size` - Minimum number of EC2 instances in cluster (default: `0`)
- `max_size` - Maximum number of EC2 instances in cluster (default: `1`)
- `enabled_metrics` - A list of metrics to gather for the cluster
- `private_subnet_ids` - A list of private subnet IDs to launch cluster instances
- `scale_up_cooldown_seconds` - Number of seconds before allowing another scale up activity (default: `300`)
- `scale_down_cooldown_seconds` - Number of seconds before allowing another scale down activity (default: `300`)
- `high_cpu_evaluation_periods` - Number of evaluation periods for high CPU alarm (default: `2`)
- `high_cpu_period_seconds` - Number of seconds in an evaluation period for high CPU alarm (default: `300`)
- `high_cpu_threshold_percent` - Threshold as a percentage for high CPU alarm (default: `90`)
- `low_cpu_evaluation_periods` - Number of evaluation periods for low CPU alarm (default: `2`)
- `low_cpu_period_seconds` - Number of seconds in an evaluation period for low CPU alarm (default: `300`)
- `low_cpu_threshold_percent` - Threshold as a percentage for low CPU alarm (default: `10`)
- `high_memory_evaluation_periods` - Number of evaluation periods for high memory alarm (default: `2`)
- `high_memory_period_seconds` - Number of seconds in an evaluation period for high memory alarm (default: `300`)
- `high_memory_threshold_percent` - Threshold as a percentage for high memory alarm (default: `90`)
- `low_memory_evaluation_periods` - Number of evaluation periods for low memory alarm (default: `2`)
- `low_memory_period_seconds` - Number of seconds in an evaluation period for low memory alarm (default: `300`)
- `low_memory_threshold_percent` - Threshold as a percentage for low memory alarm (default: `10`)
- `project` - Name of project this cluster is for (default: `Unknown`)
- `environment` - Name of environment this cluster is targeting (default: `Unknown`)

## Outputs

- `id` - The container service cluster ID
- `name` - The container service cluster name
- `container_instance_security_group_id` - Security group ID of the EC2 container instances
- `container_instance_ecs_for_ec2_service_role_name` - Name of IAM role associated with EC2 container instances
- `ecs_service_role_name` - Name of IAM role for use with ECS services
- `ecs_autoscale_role_name` - Name of IAM role for use with ECS service autoscaling
- `ecs_service_role_arn` - ARN of IAM role for use with ECS services
- `ecs_autoscale_role_arn` - ARN of IAM role for use with ECS service autoscaling
