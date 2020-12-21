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
variable "aws_vpc_cidr_block" {
  type = map
}
variable "aws_sg_alb_ingress_insecure_port" {}
variable "aws_sg_alb_ingress_secure_port" {}
variable "container_port" {}
variable "health_check_path" {
  description = "Http path for task health check"
  default     = "/"
}


variable "availability_zones" {}
variable "private_subnets" {
  type = map(list(string))
}
variable "public_subnets" {
   type = map(list(string))
}

variable "container_image" {
  type = string
  description = "Container image"
}
variable "google_id" {
  type = string
  description = "Id of the sayu's google account"
}
variable "google_secret" {
  type = string
  description = "secret of the sayu's google account"
}
variable "secret" {
  type = string
  description = "secret to encrypt session"
}
variable "nextauth_url" {
  type = string
  description = "Production URL"
}

variable "container_cpu" {}
variable "container_memory" {}
variable "allocated_storage" {}
variable "instance_class" {}
variable "database_name" {}
