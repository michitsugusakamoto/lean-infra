resource "aws_ecs_cluster" "default" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = var.name
  }
}

resource "aws_ecs_task_definition" "api" {
  family                  = "${var.name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048

  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name         = "api"
      image        = "259798983143.dkr.ecr.ap-northeast-1.amazonaws.com/sakamoto-learn-api"
      cpu          = 1024
      memory       = 2048
      essential    = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_USER"
          value = var.db_user
        },
        {
          name  = "DB_PASS"
          value = var.db_pass
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        } 
      ]
    },
  ])
}

resource "aws_ecs_service" "api" {
  name = "api"

  cluster              = aws_ecs_cluster.default.id
  task_definition      = aws_ecs_task_definition.api.arn
  launch_type          = "FARGATE"
  desired_count        = var.is_staging_and_staging_off ? 0 : var.is_production ? 2 : 1
  force_new_deployment = true

  load_balancer {
    target_group_arn = var.target_group_api
    container_name   = "api"
    container_port   = 8080
  }

  network_configuration {
    subnets         = var.subnets
    security_groups = [var.ecs_task_sg]
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}

#ui
resource "aws_ecs_task_definition" "ui" {
  family                = "${var.name}-ui"

  // 坂元追記
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  // ここまで

  container_definitions = jsonencode([
    {
      name         = "ui"
      image        = "259798983143.dkr.ecr.ap-northeast-1.amazonaws.com/sakamoto-learn-ui"
      cpu          = 1024
      memory       = 2048
      essential    = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ui" {
  name = "ui"

  cluster              = aws_ecs_cluster.default.id
  task_definition      = aws_ecs_task_definition.ui.arn

  launch_type          = "FARGATE"
  desired_count        = var.is_staging_and_staging_off ? 0 : var.is_production ? 2 : 1
  force_new_deployment = true

  load_balancer {
      target_group_arn = var.target_group_ui
      container_name   = "ui"
      container_port   = 3000
  }

  network_configuration {
      subnets         = var.subnets
      security_groups = [var.ecs_task_sg]
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }
}