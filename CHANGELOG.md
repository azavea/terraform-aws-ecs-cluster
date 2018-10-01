## 2.0.0

- Remove `ecs_autoscale_role_name` and `ecs_autoscale_role_arn` outputs.
- Remove Autoscaling IAM role and policy attachment. 
- Migrate to using `aws_launch_template` vs. `aws_launch_configuration` (requires an AWS provider `>= 1.34.0`).
- Add `cpu_credit_specification` to enable support for EC2 burstable performance instances.
- Add `detailed_monitoring` to enable support for CloudWatch detailed monitoring.

## 1.1.0

- Add output for Autoscaling Group name via `container_instance_autoscaling_group_name`.

## 1.0.0

- Renames `cloud_config` to `cloud_config_content`.
- Adds `cloud_config_content_type` to supply the content type for the `cloud-config` content.

## 0.8.1

- Use `owners` argument for `aws_ami` instead of owner-alias filter.

## 0.8.0

- Add support for automatically using the latest ECS AMI in launch configuration.

## 0.7.0

- Use `title` function to ensure that resource names are in CamelCase, even if `var.environment` is lowercase.

## 0.6.0

- Output ARN for Container Instance service role.

## 0.5.0

- Add `name_prefix` to launch configuration.
- Ensure that ASG has `create_before_destory` lifecycle block.

## 0.4.0

- Create ECS Service and Autoscaling IAM roles.
- Output IAM Role names and ARNs.

## 0.3.0

- Add support for customizing launch configuration `root_block_device`.

## 0.2.0

- Add support for Terraform 0.9.3; update `aws_iam_instance_profile` attributes.

## 0.1.0

- Initial release.
