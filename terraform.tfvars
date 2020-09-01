aws_region = "us-west-2"
aws_zone = "us-west-2a"
aws_vpc_cidr_block = "10.0.0.0/16"
aws_public_subnet_cidr_block = "10.0.0.0/24"
aws_private_subnet_cidr_block = "10.0.1.0/24"
app_name = "lcm-sayu"
app_environment = "development"
aws_sg_alb_ingress_insecure_port = 80
aws_sg_alb_ingress_secure_port = 443
container_port = 8080
health_check_path = "/health"