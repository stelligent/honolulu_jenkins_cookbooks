require 'aws-sdk-core'

Given(/^I can access the AWS environment$/) do
  @ec2 = Aws::EC2.new(region: ENV["region"])
  resp = @ec2.describe_vpcs()
end

Given(/^I know what VPC to look at$/) do
  vpcid = ENV["vpcid"]
  resp = @ec2.describe_vpcs(vpc_ids: [vpcid])
end

When(/^I lookup the VPC information$/) do
  vpcid = ENV["vpcid"]
  resp = @ec2.describe_vpcs(vpc_ids: [vpcid])
  @vpc = resp.vpcs.first
end

Then(/^I should see an internet gateway$/) do
  igws = @ec2.describe_internet_gateways(filters: [{name: "attachment.vpc-id", values: [@vpc.vpc_id]}]).internet_gateways
  expect(igws.size).to be(1), "There should only be one internet gateway per VPC"
  @igw = igws.first
end

Then(/^I should see "(.*?)" private subnets$/) do |arg1|
  subnets = @ec2.describe_subnets(filters: [{name: "vpc-id", values: [@vpc.vpc_id]}]).subnets

  private_subnets = []

  subnets.each do |subnet|
    route_tables = @ec2.describe_route_tables(filters: [{name: "association.subnet-id", values: [subnet.subnet_id]}]).route_tables.first
    igw_routes = route_tables.routes.select do |route|
      route.gateway_id == @igw.internet_gateway_id
    end
    if igw_routes.size == 0
      private_subnets << subnet
    end


  end

  expect(private_subnets.size).to be(arg1.to_i), "The number of public subnets is incorrect. (Expected #{arg1} got #{private_subnets.size})"
end

Then(/^I should see "(.*?)" public subnets$/) do |arg1|
  subnets = @ec2.describe_subnets(filters: [{name: "vpc-id", values: [@vpc.vpc_id]}]).subnets

  @public_subnets = []

  subnets.each do |subnet|
    route_tables = @ec2.describe_route_tables(filters: [{name: "association.subnet-id", values: [subnet.subnet_id]}]).route_tables.first
    igw_routes = route_tables.routes.select do |route|
      route.gateway_id == @igw.internet_gateway_id
    end
    if igw_routes.size != 0
      @public_subnets << subnet
    end


  end

  expect(@public_subnets.size).to be(arg1.to_i), "The number of public subnets is incorrect. (Expected #{arg1} got #{@public_subnets.size})"
end


Then(/^I should see a bastion host$/) do
  public_subnet_id = @public_subnets.first.subnet_id
  public_instances = @ec2.describe_instances(filters: [{name: "subnet-id", values: [public_subnet_id]}]).reservations
  bastion = nil
  public_instances.each do |instance|
    instance.instances.first.tags.each do |tag|
      if tag.key == "Name" and tag.value.include? "Bastion"
        bastion = instance
      end
    end
  end

  expect(bastion).to be, "Did not find Bastion host in public subnet"

end

Then(/^I should see a public route table$/) do
  public_route_tables = []

  route_tables = @ec2.describe_route_tables(filters: [{name: "vpc-id", values: [@vpc.vpc_id]}]).route_tables
  
  route_tables.each do |table|
    
    igw_routes = table.routes.select do |route|
      route.gateway_id == @igw.internet_gateway_id
    end

    if igw_routes.size != 0
      public_route_tables << table
    end

  end

  expect(public_route_tables.size).to be(1), "The number of public route tables is incorrect. (Expected 1 got #{public_route_tables.size})"
end

Then(/^I should see a NAT instance$/) do
  public_subnet_id = @public_subnets.first.subnet_id
  public_instances = @ec2.describe_instances(filters: [{name: "subnet-id", values: [public_subnet_id]}]).reservations
  @nat = nil
  public_instances.each do |instance|
    instance.instances.first.tags.each do |tag|
      if tag.key == "Name" and tag.value.include? "NAT"
        @nat = instance
      end
    end
  end

  expect(@nat).to be, "Did not find NAT instance in public subnet"
end

Then(/^I should see a private route table$/) do
  # get all the route tables for the vpc, then filter out the ones that don't go to the IGW
  @private_route_tables = []

  route_tables = @ec2.describe_route_tables(filters: [{name: "vpc-id", values: [@vpc.vpc_id]}]).route_tables
  
  route_tables.each do |table|
    # ignore the main route table
    if (table.associations.first.main == false)     
      igw_routes = table.routes.select do |route|
        route.gateway_id == @igw.internet_gateway_id
      end

      if igw_routes.size == 0
        @private_route_tables << table
      end
    end
  end

  expect(@private_route_tables.size).to be(1), "The number of private route tables is incorrect. (Expected 1 got #{@private_route_tables.size})"
end

Then(/^I should see that the private route table routes to the NAT instance$/) do
  found_nat_route = false

  nat_instance_id = @nat.instances.first.instance_id

  route_table = @private_route_tables.first
  route_table.routes.each do |route|
    if route.instance_id == nat_instance_id
      found_nat_route = true
    end
  end
end

When(/^I look up the bastion host for the VPC$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^I should see it is a "(.*?)" instance$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^I should see that it is associated with an elastic IP$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^I should see that its security group allows port "(.*?)"$/) do |arg1|
  pending # express the regexp above with the code you wish you had
end

Then(/^I should be able to SSH into that instance$/) do
  pending # express the regexp above with the code you wish you had
end

When(/^I look up the NAT host for the VPC$/) do
  pending # express the regexp above with the code you wish you had
end

