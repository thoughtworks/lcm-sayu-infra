
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = lookup(var.aws_vpc_cidr_block, terraform.workspace)
  tags = {
    Name = "${var.app_name}-vpc-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-igw-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}


# Public Subnet
resource "aws_subnet" "public" {
  count                   = length(lookup(var.public_subnets, terraform.workspace))
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(lookup(var.public_subnets, terraform.workspace), count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.app_name}-public-subnet-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(lookup(var.private_subnets, terraform.workspace), count.index)
  availability_zone = element(var.availability_zones, count.index)
  count             = length(lookup(var.private_subnets, terraform.workspace))
  tags = {
    Name = "${var.app_name}-private-subnet-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Route table for public subnet, going through the internet gateway
 resource "aws_route_table" "public" {
  count  = length(lookup(var.public_subnets, terraform.workspace))
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-route-table-public-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route" "public" {
  count                  = length(compact(lookup(var.public_subnets, terraform.workspace)))
  route_table_id         = element(aws_route_table.public.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = element(aws_internet_gateway.main.*.id, count.index)
}


 resource "aws_route_table_association" "public" {
  count          = length(lookup(var.public_subnets, terraform.workspace))
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id =  element(aws_route_table.public.*.id, count.index)
}

 
# Attach NAT gateway to private subnet
resource "aws_eip" "nat" {
  count = length(lookup(var.private_subnets, terraform.workspace))
  vpc = true
  tags = {
    Name = "${var.app_name}-eip-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "main" {
  count         = length(lookup(var.private_subnets, terraform.workspace))
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  depends_on    = [aws_internet_gateway.main]

  tags = {
    Name = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# Route table for private subnet, where traffic is routed through the NAT gateway

resource "aws_route_table" "private" {
  count  = length(lookup(var.private_subnets, terraform.workspace))
  vpc_id = aws_vpc.main.id
   tags = {
    Name = "${var.app_name}-route-table-private-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route" "private" {
  count                  = length(compact(lookup(var.private_subnets, terraform.workspace)))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(lookup(var.private_subnets, terraform.workspace))
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}