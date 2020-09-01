# Network Setup: VPC, Subnet, IGW, Routes 

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.aws_vpc_cidr_block
  tags = {
    Name = "lcm-sayu-vpc"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.aws_public_subnet_cidr_block
  availability_zone       = var.aws_zone
  map_public_ip_on_launch = true
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_cidr_block
  availability_zone = var.aws_zone
}