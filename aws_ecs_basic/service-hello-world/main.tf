data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_cloudwatch_log_group" "hello_world" {
  name              = "hello_world"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "hello_world" {
  family                   = "hello_world"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions    = <<EOF
[
  {
    "name": "hello_world",
    "image": "hello-world",
    "cpu": 0,
    "memory": 128,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.region}",
        "awslogs-group": "hello_world",
        "awslogs-stream-prefix": "presto-ecs"
      }
    }
  }
]
EOF
}

resource "aws_ecs_service" "hello_world" {
  name            = "hello_world"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.hello_world.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  network_configuration {
    subnets = var.target_subnets
  }
  propagate_tags = "TASK_DEFINITION"
  #load_balancer {
  #  target_group_arn = aws_lb_target_group.example_client_app.arn
  #  container_name   = "example-client-app"
  #  container_port   = 9090
  #}
  enable_execute_command = true
}
