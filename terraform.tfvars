aws_region = "us-west-2"
aws_vpc_cidr_block = "10.0.0.0/16"
app_name = "lcm-sayu"
environment = "development"
aws_sg_alb_ingress_insecure_port = 80
aws_sg_alb_ingress_secure_port = 443
container_port = 80
health_check_path = "/health"
availability_zones  = ["us-west-2a", "us-west-2b"]
private_subnets     = ["10.0.0.0/24", "10.0.1.0/24"]
public_subnets      = ["10.0.2.0/24", "10.0.3.0/24"]
***REMOVED***
container_environment = []
container_cpu = 256
container_memory = 512