variable "app_name" {
  type = string
  description = "Application name"
}
variable "aws_sg_alb_ingress_insecure_port" {}
variable "aws_sg_alb_ingress_secure_port" {}

variable "vpc_id"{}
variable "private_subnets_ids" {
  type = list
}
variable "public_subnets_ids" {
   type = list
}
variable "health_check_path" {
  description = "Http path for task health check"
  default     = "/"
}

variable "certificate_arn" {
  description = "Certificate arn created in vpc"
}