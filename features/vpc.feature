@jenkins
Feature: Scripted install of Jenkins
    As a continuous delivery engineer
    I would like Jenkins to be installed and configured correctly
    so that that my Jenkins server will work as expected

    Background:
        Given I can access the AWS environment
        And I know what VPC to look at

    Scenario: The VPC is configured correctly
        When I lookup the VPC information
        Then I should see a private subnet
        And  I should see a public subnet
        And  I should see an internet gateway
        And  I should see a bastion host
        And  I should see a public route table
        And  I should see that the public route table routes to the internet gateway
        And  I should see a NAT instance
        And  I should see a private route table
        And  I should see that the private route table routes to the NAT instance

    Scenario: The Bastion Host is configured correctly
        When I look up the bastion host for the VPC
        Then I should see that it is part of an autoscaling group
        And  I should see that it is associated with an elastic IP
        And  I should see that its security group allows port 22
        And  I should be able to SSH into that instance


