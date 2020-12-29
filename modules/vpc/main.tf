
# Create VPC
resource "aws_vpc" "main" {
  cidr_block = lookup(var.aws_vpc_cidr_block, terraform.workspace)
  tags = {
    Name = "${var.app_name}-vpc-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-igw-${terraform.workspace}"
    Environment = terraform.workspace
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
    Environment = terraform.workspace
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
    Environment = terraform.workspace
  }
}

# Route table for public subnet, going through the internet gateway
 resource "aws_route_table" "public" {
  count  = length(lookup(var.public_subnets, terraform.workspace))
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.app_name}-route-table-public-${count.index}-${terraform.workspace}"
    Environment = terraform.workspace
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
data "aws_ami" "amazon_linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }
}

resource "aws_security_group" "nat" {
  name   = "${var.app_name}-nat-gateway-${terraform.workspace}"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [var.security_group_ecs_task]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-nat-gateway-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_network_interface" "nat" {
  count             = length(lookup(var.private_subnets, terraform.workspace))
  subnet_id         = element(aws_subnet.public.*.id, count.index)
  security_groups   = [aws_security_group.nat.id]
  source_dest_check = false

  tags = {
    Name = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_eip" "nat" {
  count = length(lookup(var.private_subnets, terraform.workspace))
  vpc = true
  tags = {
    Name = "${var.app_name}-eip-${count.index}-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_eip_association" "nat" {
  count                = length(lookup(var.private_subnets, terraform.workspace))
  network_interface_id = aws_network_interface.nat[count.index].id
  allocation_id        = aws_eip.nat[count.index].id
}

resource "aws_launch_template" "nat" {
  count       = length(lookup(var.private_subnets, terraform.workspace))
  name_prefix = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
  image_id    = data.aws_ami.amazon_linux_ami.id
  user_data   = base64encode(file("${path.module}/definitions/nat-gateway-init.sh"))

  network_interfaces {
    network_interface_id = aws_network_interface.nat[count.index].id
  }

  tags = {
    Name = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_autoscaling_group" "nat" {
  count              = length(lookup(var.private_subnets, terraform.workspace))
  name_prefix        = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
  desired_capacity   = 1
  min_size           = 1
  max_size           = 1
  availability_zones = [element(var.availability_zones, count.index)]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.nat[count.index].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = var.nat_gateway_instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-nat-gateway-${count.index}-${terraform.workspace}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = terraform.workspace
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route table for private subnet, where traffic is routed through the NAT gateway

resource "aws_route_table" "private" {
  count  = length(lookup(var.private_subnets, terraform.workspace))
  vpc_id = aws_vpc.main.id
   tags = {
    Name = "${var.app_name}-route-table-private-${count.index}-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_route" "private" {
  count                  = length(compact(lookup(var.private_subnets, terraform.workspace)))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = element(aws_network_interface.nat.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(lookup(var.private_subnets, terraform.workspace))
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

# DNS
resource "aws_route53_zone" "public" {
  name = "misayu.cl"

  tags = {
    Name = "${var.app_name}-aws-route53-zone-public-${terraform.workspace}"
    Environment = terraform.workspace
  }
}

locals {
  domains = ["www.misayu.cl", "misayu.cl"]
}

resource "aws_route53_record" "domains_alias" {
  count = length(local.domains)
  zone_id = aws_route53_zone.public.zone_id
  name    = local.domains[count.index]
  type    = "A"

  alias {
    name                   = var.aws_alb_dns_name
    zone_id                = var.aws_alb_zone_id
    evaluate_target_health = true
  }
}

# Certificate configuration
resource "aws_acm_certificate" "sayu_cert" {
  domain_name       = "*.misayu.cl"
  validation_method = "DNS"

  tags = {
     Name = "${var.app_name}-aws-acm-certificate-sayu-cert-${terraform.workspace}"
    Environment = terraform.workspace
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "sayu_cert_validation_record" {
  count = 1
  allow_overwrite = true
  name            =  tolist(aws_acm_certificate.sayu_cert.domain_validation_options)[0].resource_record_name
  records         = [ tolist(aws_acm_certificate.sayu_cert.domain_validation_options)[0].resource_record_value ]
  ttl             = 60
  type            = tolist(aws_acm_certificate.sayu_cert.domain_validation_options)[0].resource_record_type
  zone_id         = aws_route53_zone.public.zone_id
}

resource "aws_acm_certificate_validation" "sayu_cert_validation" {
  depends_on = [aws_acm_certificate.sayu_cert, aws_route53_record.sayu_cert_validation_record]

  certificate_arn         = aws_acm_certificate.sayu_cert.arn
  validation_record_fqdns = [ for record in aws_route53_record.sayu_cert_validation_record : record.fqdn ]
}