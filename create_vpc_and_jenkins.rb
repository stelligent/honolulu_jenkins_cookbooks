#Copyright (c) 2014 Stelligent Systems LLC
#
#MIT LICENSE
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

STDOUT.sync = true

require 'aws-sdk-core'
require 'trollop'

# we set up a CLoudFormation stack, and we need to know if it's done yet. These are the statuses indicating "not done yet"
PROGRESS_STATUSES = [ "CREATE_IN_PROGRESS",
  "ROLLBACK_IN_PROGRESS",
  "DELETE_IN_PROGRESS",
  "UPDATE_IN_PROGRESS",
  "UPDATE_COMPLETE_CLEANUP_IN_PROGRESS",
  "UPDATE_ROLLBACK_IN_PROGRESS",
  "UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS" ]

# checks to see if the cfn stack is done yet
def stack_in_progress cfn_stack_name
  status = @cfn.describe_stacks(stack_name: cfn_stack_name).stacks.first[:stack_status]
  return PROGRESS_STATUSES.include? status
end

# used to print status without newlines
def print_and_flush(str)
  print str
  STDOUT.flush
end


def create_vpc_stack opts
  # create a cfn stack with all the resources the opsworks stack will need
  @cfn = Aws::CloudFormation.new 
  cfn_stack_name = "HonoluluAnswers-VPC-#{@timestamp}"
  @cfn.create_stack stack_name: cfn_stack_name, template_body: File.open("vpc.template", "rb").read, disable_rollback: true, timeout_in_minutes: 20, parameters: [
      { parameter_key: "KeyName",    parameter_value: opts[:keyname] }
    ]

  print_and_flush "creating VPC..."
  while (stack_in_progress cfn_stack_name)
    print_and_flush "."
    sleep 10
  end
  puts

  # get the resource names out of the cfn stack so we can pass themto opsworks
  resources = {}
  @cfn.describe_stacks(stack_name: cfn_stack_name).stacks.first[:outputs].each do |output|
    resources[output[:output_key]] = output[:output_value]
  end

  resources
end

def create_jenkins_stack opts, resources
  vpc = resources["VPC"]
  publicSubnet = resources["PublicSubnet"]
  privateSubnetA = resources["PrivateSubnetA"]
  privateSubnetB = resources["PrivateSubnetB"]

  cfn_stack_name = "HonoluluAnswers-Jenkins-#{@timestamp}"
  @cfn.create_stack stack_name: cfn_stack_name, template_body: File.open("jenkins.template", "rb").read, timeout_in_minutes: 45, disable_rollback: true, capabilities: ["CAPABILITY_IAM"], parameters: [
      { parameter_key: "domain",            parameter_value: opts[:domain]  },
      { parameter_key: "adminEmailAddress", parameter_value: opts[:email]   },
      { parameter_key: "vpc",               parameter_value: vpc            },
      { parameter_key: "publicSubnet",      parameter_value: publicSubnet   },
      { parameter_key: "privateSubnetA",    parameter_value: privateSubnetA },
      { parameter_key: "privateSubnetB",    parameter_value: privateSubnetB }
    ]

  print_and_flush "creating Jenkins server..."
  while (stack_in_progress cfn_stack_name)
    print_and_flush "."
    sleep 10
  end
  puts
end

# using trollop to do command line options
opts = Trollop::options do
  opt :region, 'The AWS region to use', :type => String, :default => "us-west-2"
  opt :keyname, 'The EC2 keypair to use on the instances created', :type => String, :required => true
  opt :domain, 'The Route 53 Hosted Zone that the Jenkins server will deploy to', :type => String, :default => "example.com"
end

puts "You're creating a Honolulu Answers VPC and Jenkins instance in the #{opts[:region]} region."
@timestamp = Time.now.strftime "%Y%m%d%H%M%S"

aws_region = opts[:region]
# curious what the AWS calls look like? set http_wire_trace to true.
Aws.config = { region: aws_region, http_wire_trace: false }

resources = create_vpc_stack opts
puts "Giving the VPC a chance to generate security groups..."
sleep 30
create_jenkins_stack opts, resources


