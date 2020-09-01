Feature: This module should create all resources for Network

    Scenario: VPC should be created
        Given I have aws_vpc resource configured
        When its name is "main"
        And its type is "aws_vpc"
        Then its cidr_block must be "10.0.0.0/16"

    Scenario: Internet Gateway should be created
        Given I have aws_internet_gateway resource configured
        When its name is "main"
        And its type is "aws_internet_gateway"
        Then its mode must be "managed"
    
    Scenario: Public subnet should be created
        Given I have aws_subnet resource configured
        When its name is "public"
        And its cidr_block is "10.0.0.0/24"
        And its availability_zone is "us-west-2a"
        And its map_public_ip_on_launch is true