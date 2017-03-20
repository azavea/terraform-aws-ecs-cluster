#cloud-config

bootcmd:
  - mkdir -p /etc/ecs
  - echo 'ECS_CLUSTER=${ecs_cluster_name}' >> /etc/ecs/ecs.config
