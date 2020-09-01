Feature: This module should create all resources for Network

    Scenario: VPC should be created
        Given I have aws_vpc resource configured
        When its name is "main"
        And its type is "aws_vpc"
        And its cidr_block is "10.0.0.0/16"
        Then it must contain tags
        And its name must be "lcm-sayu-vpc"

    Scenario: Internet Gateway should be created
        Given I have aws_internet_gateway resource configured
        When its name is "main"
        And its type is "aws_internet_gateway"
        Then it must contain tags
        And its name must be "lcm-sayu-igw"
    
    Scenario: Public subnet should be created
        Given I have aws_subnet resource configured
        When its name is "public"
        And its cidr_block is "10.0.0.0/24"
        And its availability_zone is "us-west-2a"
        And its map_public_ip_on_launch is true
        Then it must contain tags
        And its name must be "lcm-sayu-public-subnet"

    Scenario: Private subnet should be created
        Given I have aws_subnet resource configured
        When its name is "private"
        And its cidr_block is "10.0.1.0/24"
        And its availability_zone is "us-west-2a"
        Then it must contain tags
        And its name must be "lcm-sayu-private-subnet"
    
    Scenario: Route table to public subnet should be created
        Given I have aws_route_table resource configured
        When its name is "public"
        And its type is "aws_route_table"

    Scenario: Route to public subnet should be created
        Given I have aws_route resource configured
        When its name is "public"
        And its type is "aws_route"
        And its destination_cidr_block is "0.0.0.0/0"

    Scenario: Route table association to public subnet should be created
        Given I have aws_route_table_association resource configured
        When its name is "public"
        And its type is "aws_route_table_association"

    Scenario: Elastic IP should be created
        Given i have aws_eip resource configured
        When its name is "nat"
        And its vpc is true
    
    Scenario: NAT Gateway should be created
        Given I have aws_nat_gateway resource configured
        When its name is "main"

    Scenario: Route table to private subnet should be created
        Given I have aws_route_table resource configured
        When its name is "private"
        And its type is "aws_route_table"

    Scenario: Route to private subnet should be created
        Given I have aws_route resource configured
        When its name is "private"
        And its type is "aws_route"
        And its destination_cidr_block is "0.0.0.0/0"
    
    Scenario: Route table association to private subnet should be created
        Given I have aws_route_table_association resource configured
        When its name is "private"
        And its type is "aws_route_table_association"
    
    Scenario: Security Group to ALB should be created
        Given I have aws_security_group resource configured
        When its name is "lcm-sayu-sg-alb"
        And it has ingress
        And it has egress
        
        
    Scenario: Security Group to ECS Task should be created
        Given I have aws_security_group resource configured
        When its name is "lcm-sayu-sg-task"
        And it has ingress

    Scenario: ALB should be created
        Given I have aws_lb resource configured
        When its name is "lcm-sayu-alb"
        And its internal is false
        And its load_balancer_type is "application"
        And its enable_deletion_protection is false
    
    Scenario: ALB Target Group should be created
        Given I have aws_alb_target_group resource configured
        When its name is "lcm-sayu-tg"
        And its port is 80
        And its protocol is "HTTP"
        And its target_type is "ip"
        Then it must contain health_check
        And its protocol must be "HTTP"


    Scenario: ALB Listener to HTTP should be created
        Given I have aws_alb_listener resource configured
        When its name is "http"
        And its port is 80
        And its protocol is "HTTP"
        Then it must contain default_action
        And its type must be "redirect"
