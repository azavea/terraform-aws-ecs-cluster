variable "project" {
  default     = "Unknown"
  type        = string
  description = "Name of project this cluster is for"
}

variable "environment" {
  default     = "Unknown"
  type        = string
  description = "Name of environment this cluster is targeting"
}

variable "cluster_name" {
  default     = ""
  type        = string
  description = "Name of the ECS Cluster, it is optional"
}

variable "autoscaling_group_name" {
  default     = ""
  type        = string
  description = "Name of the autoscaling group for ECS Cluster, it is optional"
}

variable "security_group_name" {
  default     = ""
  type        = string
  description = "Name of the security group for ECS Cluster, it is optional"
}

variable "ecs_for_ec2_service_role_name" {
  default     = ""
  type        = string
  description = "Name of IAM role for ECS Cluster, it is optional"
}

variable "ecs_service_role_name" {
  default     = ""
  type        = string
  description = "Name of IAM role for ECS Service, it is optional"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC meant to house cluster"
}

variable "ami_id" {
  default     = "ami-0b22c910bce7178b6"
  type        = string
  description = "Cluster instance Amazon Machine Image (AMI) ID"
}

variable "ami_owners" {
  default = ["self", "amazon", "aws-marketplace"]
  type    = list(string)
}

variable "lookup_latest_ami" {
  default     = false
  type        = string
  description = "Lookup the latest Amazon-owned ECS AMI"
}

variable "root_block_device_type" {
  default     = "gp2"
  type        = string
  description = "Instance root block device type"
}

variable "root_block_device_size" {
  default     = 30
  type        = number
  description = "Instance root block device size in gigabytes"
}

variable "instance_type" {
  default     = "t3.micro"
  type        = string
  description = "Instance type for cluster instances"
}

variable "cpu_credit_specification" {
  default     = "standard"
  type        = string
  description = "Credit option for CPU usage"
}

variable "detailed_monitoring" {
  default     = false
  type        = bool
  description = "If true, then detailed monitoring will be enabled on the instance"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name"
}

variable "cloud_config_content" {
  type        = string
  description = "User data supplied to launch configuration for cluster nodes"
}

variable "cloud_config_content_type" {
  default     = "text/cloud-config"
  type        = string
  description = "The type of configuration being passed in as user data"
}

variable "health_check_grace_period" {
  default     = 600
  type        = number
  description = "Time in seconds after container instance comes into service before checking health"
}

variable "override_desired_capacity" {
  default     = null
  type        = number
  description = "Override the number of EC2 instances that should be running in cluster"
}

variable "min_size" {
  default     = 1
  type        = number
  description = "Minimum number of EC2 instances in cluster"
}

variable "max_size" {
  default     = 1
  type        = number
  description = "Maximum number of EC2 instances in cluster"
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
  type        = list(string)
  description = "A list of metrics to gather for the cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs to launch cluster instances"
}
