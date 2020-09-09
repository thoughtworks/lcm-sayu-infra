variable "app_name" {
  type = string
  description = "Application name"
}

variable "vpc_id"{}
variable "container_port" {}
variable "endpoint_rds"{}
variable "random_password"{}
variable "random_username"{}
variable "container_cpu" {}
variable "container_memory" {}
variable "allocated_storage" {}
variable "container_image"{}
variable "database_name" {}
variable "private_subnets_ids" {
  type = list
}
variable "aws_alb_target_group"{}