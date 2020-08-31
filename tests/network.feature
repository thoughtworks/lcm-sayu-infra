Feature: This module should create all resources for Network

    Scenario: VPC should be created
        Given I have aws_vpc resource configured
        Then its cidr_block must be "10.0.0.0/16"