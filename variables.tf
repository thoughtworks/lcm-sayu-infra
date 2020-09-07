# Application configuration
variable "app_name" {
  type = string
  description = "Application name"
}
variable "environment" {
  type = string
  description = "Application environment"
}
variable "aws_region" {}
variable "aws_vpc_cidr_block" {}
variable "aws_sg_alb_ingress_insecure_port" {}
variable "aws_sg_alb_ingress_secure_port" {}
variable "container_port" {}
variable "health_check_path" {
  description = "Http path for task health check"
  default     = "/health"
}


variable "availability_zones" {}
variable "private_subnets" {
  type = list(string)
}
variable "public_subnets" {
   type = list(string)
}

variable "container_image" {
  type = string
  description = "Container image"
}

variable "container_cpu" {}
variable "container_memory" {}
variable "allocated_storage" {}
variable "instance_class" {}
variable "database_name" {}