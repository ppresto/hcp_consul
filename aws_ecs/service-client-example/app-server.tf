resource "aws_ecs_service" "fake-service-server" {
  name            = "${var.name}-server"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.server-example.arn
  desired_count   = 1
  network_configuration {
    subnets = var.target_subnets
  }
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"
  enable_execute_command = true

  service_registries {
    registry_arn = aws_service_discovery_service.server.arn
  }
}

resource "aws_ecs_task_definition" "server-example" {
  family                   = "${var.name}-server"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<EOF
[
  {
    "name": "${var.name}-server",
    "image": "ghcr.io/lkysow/fake-service:v0.21.0",
    "essential":true,
    "logConfiguration":{
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.region}",
        "awslogs-group": "${aws_cloudwatch_log_group.service.name}",
        "awslogs-stream-prefix": "${var.name}-server"
      }
    },
    "environment": [
      {
        "name":"NAME",
        "value":"${var.name}-server"
      }
    ],
    "portMappings": [
      {
        "containerPort":9090,
        "hostPort":9090,
        "protocol":"tcp"
      }
    ],
    "cpu":0,
    "mountPoints":[],
    "volumesFrom":[]
  }
]
EOF
}