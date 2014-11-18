require 'aws-sdk-core'

Given(/^I can access the AWS environment$/) do
  @ec2 = Aws::EC2::Client.new(region: ENV["region"])
  resp = @ec2.describe_vpcs()
end

Given(/^I know what VPC to look at$/) do
  vpcid = ENV["vpc"]
  resp = @ec2.describe_vpcs(vpc_ids: [vpcid])
  @vpc = resp.vpcs.first
end

When(/^I lookup the VPC information$/) do
  expect(@vpc).to be
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
  @instance_to_check = nil
  public_instances.each do |instance|
    instance.instances.first.tags.each do |tag|
      if tag.key == "Name" and tag.value.include? "Bastion"
        @instance_to_check = instance
      end
    end
  end

  expect(@instance_to_check).to be, "Did not find Bastion host in public subnet"

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
  instances = @ec2.describe_instances(filters: [{name: "vpc-id", values: [@vpc.vpc_id]}]).reservations
  @instance_to_check = nil
  instances.each do |instance|
    instance.instances.first.tags.each do |tag|
      if tag.key == "Name" and tag.value.include? "Bastion"
        @instance_to_check = instance
      end
    end
  end

  expect(@instance_to_check).to be, "Did not find Bastion host in VPC"
end

Then(/^I should see it is a "(.*?)" instance$/) do |arg1|
  instance_type = @instance_to_check.instances.first.instance_type
  expect(instance_type).to eq(arg1), "Instance is wrong type, expect '#{arg1}', but found '#{instance_type}'"
end

Then(/^I should see that it is associated with an elastic IP$/) do
  expect(@instance_to_check.instances.first.network_interfaces.size).to be > 0
  eips_for_instance = @ec2.describe_addresses.addresses.select {|eip|  eip.instance_id == @instance_to_check.instances.first.instance_id}
  expect(eips_for_instance.size).to be(1), "Expected one EIP associated with the instance, found #{eips_for_instance.size}"
end

Then(/^I should see that its security group allows port "(.*?)"$/) do |arg1|

  groups = @instance_to_check.instances.first.security_groups
  expect(groups.size).to eq(1)

  @ec2.describe_security_groups(group_ids: [groups.first.group_id]).security_groups.each do |group|
    found = group.ip_permissions.select do |perm|
      perm.from_port == arg1.to_i && perm.to_port == arg1.to_i
    end
    expect(found.size).to eq(1), "Did not find port #{arg1} open in security group #{group.group_name}"
  end
end

When(/^I look up the NAT host for the VPC$/) do
  instances = @ec2.describe_instances(filters: [{name: "vpc-id", values: [@vpc.vpc_id]}]).reservations
  @instance_to_check = nil
  instances.each do |instance|
    instance.instances.first.tags.each do |tag|
      if tag.key == "Name" and tag.value.include? "NAT"
        @instance_to_check = instance
      end
    end
  end

  expect(@instance_to_check).to be, "Did not find NAT host in VPC"
end
