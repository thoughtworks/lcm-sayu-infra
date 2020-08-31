# Network Setup: VPC, Subnet, IGW, Routes 

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr_block
}

# Interner gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
