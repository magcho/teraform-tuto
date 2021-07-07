

variable "subnets" {
  type = list(string)
}
variable "lb_target_group" {}
variable "vpc_id" {}
variable "vpc_cidr_block" {}

# 9.1
resource "aws_ecs_cluster" "example" {
  name = "example"
}

# 9.2
resource "aws_ecs_task_definition" "example" {
  family                   = "example"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # 1024 = 1vCPU
  memory                   = "512"
  network_mode             = "awsvpc"
  container_definitions = jsonencode(
    [
      {
        "name" : "example",
        "image" : "nginx:latest",
        "essential" : true,
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-region" : "ap-northeast-1",
            "awslogs-stream-prefix" : "nginx",
            "awslogs-group" : "/ecs/example"
          }
        },
        "portMappings" : [
          {
            "protocol" : "tcp",
            "containerPort" : 80
          }
        ]
      }
    ]
  )
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# 9.4
resource "aws_ecs_service" "example" {
  name                              = "example-ecs-service"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]
    subnets          = var.subnets
  }

  load_balancer {
    target_group_arn = var.lb_target_group.arn
    container_name   = "example"
    container_port   = 80
  }

  # lifecycle {
  # ignore_changes = [task_definition]
  # }
}

module "nginx_sg" {
  source      = "../security_group"
  name        = "nginx-sg"
  vpc_id      = var.vpc_id
  port        = 80
  cidr_blocks = [var.vpc_cidr_block]
}


# 9.5
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/example"
  retention_in_days = 180
}

# 9.6
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 9.7
data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

# 9.8
module "ecs_task_execution_role" {
  source     = "../iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}
