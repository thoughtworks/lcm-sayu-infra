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

