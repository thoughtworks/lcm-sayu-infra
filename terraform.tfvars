aws_region = "us-west-2"
aws_vpc_cidr_block = {
    dev = "10.0.0.0/16",
    prod = "10.1.0.0/16"
}

app_name = "lcm-sayu"
environment = "development"
aws_sg_alb_ingress_insecure_port = 80
aws_sg_alb_ingress_secure_port = 443
container_port = 80
health_check_path = "/"
availability_zones  = ["us-west-2a", "us-west-2b"]

private_subnets      = {
    dev = ["10.0.0.0/24", "10.0.1.0/24"]
    prod = ["10.1.0.0/24", "10.1.1.0/24"]
}

public_subnets      = {
   
    dev = ["10.0.2.0/24", "10.0.3.0/24"]
    prod = ["10.1.2.0/24", "10.1.3.0/24"]
}

***REMOVED*** 
container_cpu = 256
container_memory = 512

allocated_storage = 20
instance_class = "db.t2.micro"
database_name = "lcmsayudb"
