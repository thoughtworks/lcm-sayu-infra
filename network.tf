# Network Setup: VPC, Subnet, IGW, Routes 

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = lookup(var.aws_vpc_cidr_block, terraform.workspace)
  tags = {
    Name = "${var.app_name}-vpc-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-igw-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  count                   = length(lookup(var.public_subnets, terraform.workspace))
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(lookup(var.public_subnets, terraform.workspace), count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.app_name}-public-subnet-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(lookup(var.private_subnets, terraform.workspace), count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(lookup(var.private_subnets, terraform.workspace))
  tags = {
    Name = "${var.app_name}-private-subnet-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Route table for public subnet, going through the internet gateway
 resource "aws_route_table" "public" {
  count  = length(lookup(var.public_subnets, terraform.workspace))
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-route-table-public-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route" "public" {
  count                  = length(compact(lookup(var.public_subnets, terraform.workspace)))
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = element(aws_internet_gateway.main.*.id, count.index)
}


 resource "aws_route_table_association" "public" {
  count          = length(lookup(var.public_subnets, terraform.workspace))
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id =  element(aws_route_table.public.*.id, count.index)
}

 
# Attach NAT gateway to private subnet
resource "aws_eip" "nat" {
  count = length(lookup(var.private_subnets, terraform.workspace))
  vpc = true
  tags = {
    Name = "${var.app_name}-eip-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(lookup(var.private_subnets, terraform.workspace))
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Route table for private subnet, where traffic is routed through the NAT gateway

resource "aws_route_table" "private" {
  count  = length(lookup(var.private_subnets, terraform.workspace))
  vpc_id = aws_vpc.main.id
   tags = {
    Name = "${var.app_name}-route-table-private-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route" "private" {
  count                  = length(compact(lookup(var.private_subnets, terraform.workspace)))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(lookup(var.private_subnets, terraform.workspace))
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# Create security group to ALB
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-sg-alb-${terraform.workspace}"
  vpc_id = aws_vpc.main.id
 
  ingress {
   protocol         = "tcp"
   from_port        = var.aws_sg_alb_ingress_insecure_port
   to_port          = var.aws_sg_alb_ingress_insecure_port
   cidr_blocks      = ["0.0.0.0/0"]
   ipv6_cidr_blocks = ["::/0"]
  }
 
  ingress {
   protocol         = "tcp"
   from_port        = var.aws_sg_alb_ingress_secure_port
   to_port          = var.aws_sg_alb_ingress_secure_port
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
  tags = {
    Name = "${var.app_name}-sg-alb-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}
# Security group to ECS Task
resource "aws_security_group" "ecs_tasks" {
  name   = "${var.app_name}-sg-task-${terraform.workspace}"
  vpc_id = aws_vpc.main.id
 
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

# Create ALB
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public.*.id
  enable_deletion_protection = false
}

resource "aws_alb_target_group" "main" {
  name        = "${var.app_name}-tg-${terraform.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  depends_on = [aws_lb.main] 
 
  health_check {
   healthy_threshold   = "3"
   interval            = "30"
   protocol            = "HTTP"
   matcher             = "200"
   timeout             = "3"
   path                = var.health_check_path
   unhealthy_threshold = "2"
  }

}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"
 
  default_action {
    target_group_arn = aws_alb_target_group.main.id
    type             = "forward"
  }
}

# Create ECR Repository 
resource "aws_ecr_repository" "main" {
  name                 = "${var.app_name}-repository-${terraform.workspace}"
  image_tag_mutability = "MUTABLE"

  tags = {
    Environment = "${terraform.workspace}"
  }
}


# Create ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
 
  policy = jsonencode({
   rules = [{
     rulePriority = 1
     description  = "keep last 10 images"
     action       = {
       type = "expire"
     }
     selection     = {
       tagStatus   = "any"
       countType   = "imageCountMoreThan"
       countNumber = 10
     }
   }]
  })
}

 # Create ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster-${terraform.workspace}"
  
  tags = {
    Name        = "${var.app_name}-cluster-${terraform.workspace}"
    Environment = "${terraform.workspace}"
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

resource "random_password" "password" {
  length = 16
  special = false
  override_special = "_%@"
}

resource "random_string" "random" {
  length = 16
  special = false
  number = false
  override_special = "_%@"
}


##################### DB #######################
resource "aws_db_instance" "rds" {
  identifier             = "${var.app_name}-database-${terraform.workspace}"
  allocated_storage      = var.allocated_storage
  engine                 = "postgres"
  engine_version         = "9.6.6"
  instance_class         = var.instance_class
  name                   = var.database_name
  username               = random_string.random.result
  password               = random_password.password.result
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  tags = {
    Environment = "${terraform.workspace}"
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
      {"name": "DATABASE_ENDPOINT", "value": aws_db_instance.rds.endpoint},
      {"name": "DATABASE_PORT", "value": "5432"},
      {"name": "DATABASE_PASSWORD", "value": random_password.password.result},
      {"name": "DATABASE_USERNAME", "value": random_string.random.result},
      {"name": "DATABASE_NAME", "value": var.database_name },
      {"name": "ENVIRONMENT", "value": terraform.workspace}
    ]
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
  }])

  tags = {
    Name        = "${var.app_name}-task-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
  depends_on = [aws_db_instance.rds]
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
   subnets          = aws_subnet.private.*.id
   assign_public_ip = false
 }
 
 load_balancer {
   target_group_arn = aws_alb_target_group.main.arn
   container_name   = "${var.app_name}-container-${terraform.workspace}"
   container_port   = var.container_port
 }
 
 lifecycle {
   ignore_changes = [task_definition, desired_count]
 }
}


/* subnet used by rds */
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.app_name}-rds-subnet-group-${terraform.workspace}"
  description = "RDS subnet group"
  subnet_ids  = aws_subnet.private.*.id
  tags = {
    Environment = "${terraform.workspace}"
  }
}


resource "aws_security_group" "rds_sg" {
  name = "${var.app_name}-sg-rds-${terraform.workspace}"
  description = "${terraform.workspace} Security Group"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.app_name}-sg-rds-${terraform.workspace}"
    Environment =  "${terraform.workspace}"
  }

  //allow traffic for TCP 5432
  ingress {
      from_port = 5432
      to_port   = 5432
      protocol  = "tcp"
  }

  // outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}