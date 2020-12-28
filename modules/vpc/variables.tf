variable "app_name" {
  type = string
  description = "Application name"
}

variable "aws_vpc_cidr_block" {
  type = map
}

variable "private_subnets" {
  type = map(list(string))
}

variable "public_subnets" {
   type = map(list(string))
}

variable "availability_zones" {}

variable "nat_gateway_instance_types" {
  type    = list(string)
  default = ["t3.nano", "t2.nano", "t3.micro", "t2.micro"]
}

variable "security_group_ecs_task" {}

variable "aws_alb_dns_name" {}

variable "aws_alb_zone_id" {}