
# Create security group to ALB
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-sg-alb-${terraform.workspace}"
  vpc_id = var.vpc_id
 
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

# Create ALB
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb-${terraform.workspace}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets_ids
  enable_deletion_protection = false
}


resource "aws_alb_target_group" "main" {
  name        = "${var.app_name}-tg-${terraform.workspace}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
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
