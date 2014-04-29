@jenkins
Feature: Scripted install of Jenkins
    As a continuous delivery engineer
    I would like Jenkins to be installed and configured correctly
    so that that my Jenkins server will work as expected

    Background:
        Given I am testing the local environment

    Scenario: The OpsWorks stack is set up correctly
        When I lookup the OpsWorks stack for the local machine
        Then I should see a stack with one layer
        And  the layer should be named "Jenkins Server Layer"
        And  I should see a layer with one instance
        And  the instance should be named "jenkins1"
        And  the instance should be running

    Scenario: Is the hostname set correctly?
        When I run "hostname"
        Then I should see "jenkins1"

    Scenario: Is ruby 1.9.3 installed
        When I run "ruby -v"
        Then I should see "ruby 1.9.3"

    Scenario: Is the server listening on port 80?
        When I run "netstat -antu | grep 80"
        Then I should see ":::80"

    Scenario: Is Jenkins installed?
        When I run "ls /var/lib/jenkins/"
        Then I should see "config.xml"
        When I run "service jenkins status"
        Then I should see "is running..."

    Scenario Outline: Are the pipeline jobs present?
        When I run "ls /var/lib/jenkins/jobs"
        Then I should see <jobname>
        Examples: 
            | jobname                     |
            | "jenkins-test"              |
            | "become-production-jenkins" |
            | "clean-gemset"              |
            | "create-new-jenkins"        |
            | "job-seed"                  |
