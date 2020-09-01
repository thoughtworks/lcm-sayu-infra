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
  tags = {
    Name = "lcm-sayu-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.aws_public_subnet_cidr_block
  availability_zone       = var.aws_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "lcm-sayu-public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.aws_private_subnet_cidr_block
  availability_zone = var.aws_zone
  tags = {
    Name = "lcm-sayu-private-subnet"
  }
}

# Route table for public subnet, going through the internet gateway
 resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}
 
 resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}