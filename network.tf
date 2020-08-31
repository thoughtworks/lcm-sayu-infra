# Network Setup: VPC, Subnet, IGW, Routes 

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr_block
}