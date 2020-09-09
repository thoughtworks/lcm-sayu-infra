variable "app_name" {
  type = string
  description = "Application name"
}
variable "vpc_id"{}
variable "private_subnets_ids" {
  type = list
}
variable "public_subnets_ids" {
   type = list
}

variable "allocated_storage" {}
variable "instance_class" {}
variable "database_name" {}
variable "random_password" {}
variable "random_username" {}
