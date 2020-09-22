resource "aws_db_instance" "rds" {
  identifier             = "${var.app_name}-database-${terraform.workspace}"
  allocated_storage      = var.allocated_storage
  engine                 = "postgres"
  engine_version         = "9.6.11"
  instance_class         = var.instance_class
  name                   = var.database_name
  username               = var.random_username
  password               = var.random_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.id
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  tags = {
    Environment = "${terraform.workspace}"
  }
}




/* subnet used by rds */
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "${var.app_name}-rds-subnet-group-${terraform.workspace}"
  description = "RDS subnet group"
  subnet_ids  = var.private_subnets_ids
  tags = {
    Environment = "${terraform.workspace}"
  }
}


resource "aws_security_group" "rds_sg" {
  name = "${var.app_name}-sg-rds-${terraform.workspace}"
  description = "${terraform.workspace} Security Group"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.app_name}-sg-rds-${terraform.workspace}"
    Environment =  "${terraform.workspace}"
  }

  //allow traffic for TCP 5432
  ingress {
      from_port = 5432
      to_port   = 5432
      protocol  = "tcp"
      security_group_id= aws_security_group.ecs_tasks.id
  }

  // outbound internet access
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}