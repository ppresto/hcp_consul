resource "aws_ecs_service" "fake-service-client" {
  name            = "${var.name}-client"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.client.arn
  desired_count   = 1
  network_configuration {
    subnets = var.target_subnets
  }
  launch_type    = "FARGATE"
  propagate_tags = "TASK_DEFINITION"
  load_balancer {
    target_group_arn = aws_lb_target_group.example_client_app.arn
    container_name   = "${var.name}-client"
    container_port   = 9090
  }
  enable_execute_command = true
}

resource "aws_ecs_task_definition" "client" {
  family                   = "${var.name}-client"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<EOF
[
  {
    "name": "${var.name}-client",
    "image": "nicholasjackson/fake-service:v0.23.0",
    "essential":true,
    "logConfiguration":{
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.region}",
        "awslogs-group": "${aws_cloudwatch_log_group.service.name}",
        "awslogs-stream-prefix": "${var.name}-client"
      }
    },
    "environment": [
      {
        "name":"NAME",
        "value":"${var.name}-client"
      },
      {
        "name": "UPSTREAM_URIS",
        "value": "http://${var.dns_fake_server}.${var.dns_namespace}:9090"
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