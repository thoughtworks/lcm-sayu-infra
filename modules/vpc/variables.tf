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

