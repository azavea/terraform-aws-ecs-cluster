variable "project" {
  default = "Unknown"
}

variable "environment" {
  default = "Unknown"
}

variable "cluster_name" {
  default = ""
}

variable "asg_name" {
  default = ""
}

variable "sg_name" {
  default = ""
}

variable "iam_role_name" {
  default = ""
}

variable "vpc_id" {}

variable "ami_id" {
  default = "ami-6944c513"
}

variable "ami_owners" {
  default = ["self", "amazon", "aws-marketplace"]
}

variable "lookup_latest_ami" {
  default = false
}

variable "root_block_device_type" {
  default = "gp2"
}

variable "root_block_device_size" {
  default = "8"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "cpu_credit_specification" {
  default = "standard"
}

variable "detailed_monitoring" {
  default = false
}

variable "key_name" {}

variable "cloud_config_content" {}

variable "cloud_config_content_type" {
  default = "text/cloud-config"
}

variable "health_check_grace_period" {
  default = "600"
}

variable "desired_capacity" {
  default = "1"
}

variable "min_size" {
  default = "1"
}

variable "max_size" {
  default = "1"
}

variable "enabled_metrics" {
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  type = "list"
}

variable "private_subnet_ids" {
  type = "list"
}

variable "scale_up_cooldown_seconds" {
  default = "300"
}

variable "scale_down_cooldown_seconds" {
  default = "300"
}

variable "high_cpu_evaluation_periods" {
  default = "2"
}

variable "high_cpu_period_seconds" {
  default = "300"
}

variable "high_cpu_threshold_percent" {
  default = "90"
}

variable "low_cpu_evaluation_periods" {
  default = "2"
}

variable "low_cpu_period_seconds" {
  default = "300"
}

variable "low_cpu_threshold_percent" {
  default = "10"
}

variable "high_memory_evaluation_periods" {
  default = "2"
}

variable "high_memory_period_seconds" {
  default = "300"
}

variable "high_memory_threshold_percent" {
  default = "90"
}

variable "low_memory_evaluation_periods" {
  default = "2"
}

variable "low_memory_period_seconds" {
  default = "300"
}

variable "low_memory_threshold_percent" {
  default = "10"
}
