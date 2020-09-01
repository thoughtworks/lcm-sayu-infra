# Application configuration
variable "app_name" {
  type = string
  description = "Application name"
}
variable "app_environment" {
  type = string
  description = "Application environment"
}
variable "aws_region" {}
variable "aws_zone" {}
variable "aws_vpc_cidr_block" {}
variable "aws_public_subnet_cidr_block" {}

