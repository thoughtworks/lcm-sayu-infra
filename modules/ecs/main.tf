# Security group to ECS Task
resource "aws_security_group" "ecs_tasks" {
  name   = "${var.app_name}-sg-task-${terraform.workspace}"
  vpc_id = var.vpc_id

  ingress {
   protocol         = "tcp"
   from_port        = var.container_port
   to_port          = var.container_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }

  egress {
   protocol         = "-1"
   from_port        = 0
   to_port          = 0
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
}


 # Create ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster-${terraform.workspace}"

  tags = {
    Name        = "${var.app_name}-cluster-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-ecsTaskExecutionRole-${terraform.workspace}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs-log-group" {
  name = "/ecs/lcm-sayu-task-${terraform.workspace}"
  retention_in_days = 30

  tags = {
    Name="/ecs/lcm-sayu-task-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.app_name}-task-${terraform.workspace}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name        = "${var.app_name}-container-${terraform.workspace}"
    image       = "${var.container_image}-${terraform.workspace}:latest"
    essential   = true
    environment = [
     {"name": "TYPEORM_HOST", "value": var.endpoint_rds },
      {"name": "TYPEORM_PORT", "value": "5432"},
      {"name": "TYPEORM_PASSWORD", "value": var.random_password},
      {"name": "TYPEORM_USERNAME", "value": var.random_username},
      {"name": "TYPEORM_DATABASE", "value": var.database_name},
      {"name": "ENVIRONMENT", "value": terraform.workspace},
      {"name": "TYPEORM_CONNECTION", "value": "postgres"},
      {"name": "TYPEORM_SYNCHRONIZE", "value": "false"},
      {"name": "TYPEORM_LOGGING", "value": "true"},
      {"name": "TYPEORM_ENTITIES", "value": "src/entity/*.js"},
      {"name": "GOOGLE_ID", "value": "${var.google_id}"},
      {"name": "GOOGLE_SECRET", "value": "${var.google_secret}"},
      {"name": "SECRET", "value": "${var.secret}"},
      {"name": "NEXTAUTH_URL", "value": "${var.nextauth_url}"},
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
    logConfiguration = {
      "logDriver": "awslogs",
      "options": {
          "awslogs-region" : var.aws_region,
          "awslogs-group" : "/ecs/lcm-sayu-task-${terraform.workspace}",
          "awslogs-stream-prefix" : "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.app_name}-task-${terraform.workspace}"
    Environment = terraform.workspace
  }
  #depends_on = [aws_db_instance.rds]
  depends_on = [var.endpoint_rds]
}


resource "aws_ecs_service" "main" {
 name                               = "${var.app_name}-service-${terraform.workspace}"
 cluster                            = aws_ecs_cluster.main.id
 task_definition                    = aws_ecs_task_definition.main.arn
 desired_count                      = 2
 deployment_minimum_healthy_percent = 50
 deployment_maximum_percent         = 200
 launch_type                        = "FARGATE"
 scheduling_strategy                = "REPLICA"

 network_configuration {
   security_groups  = [aws_security_group.ecs_tasks.id]
   subnets          = var.private_subnets_ids
   assign_public_ip = false
 }

 load_balancer {
   target_group_arn = var.aws_alb_target_group
   container_name   = "${var.app_name}-container-${terraform.workspace}"
   container_port   = var.container_port
 }

 lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}
