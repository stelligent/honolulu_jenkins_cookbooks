@jenkins
Feature: Scripted creation of VPC
    As a continuous delivery engineer
    I would like my VPC to be installed and configured correctly
    so that that my infrastructure server will work as expected

    Background:
        Given I can access the AWS environment
        And I know what VPC to look at

    Scenario: The VPC is configured correctly
        When I lookup the VPC information
        Then I should see an internet gateway
        And  I should see "1" public subnets
        And  I should see "2" private subnets
        And  I should see a bastion host
        And  I should see a public route table
        And  I should see a NAT instance
        And  I should see a private route table
        And  I should see that the private route table routes to the NAT instance

    Scenario: The Bastion Host is configured correctly
        When I look up the bastion host for the VPC
        Then I should see it is a "t1.micro" instance
        And  I should see that it is associated with an elastic IP
        And  I should see that its security group allows port "22"
        And  I should see that its security group allows port "80"
        And  I should see that its security group allows port "443"

    Scenario: The NAT is configured correctly
        When I look up the NAT host for the VPC
        Then I should see it is a "m1.small" instance
        And  I should see that it is associated with an elastic IP
        And  I should see that its security group allows port "22"
        And  I should see that its security group allows port "80"
        And  I should see that its security group allows port "443"
        And  I should see that its security group allows port "587"
        And  I should see that its security group allows port "5432"
        And  I should see that its security group allows port "9418"
