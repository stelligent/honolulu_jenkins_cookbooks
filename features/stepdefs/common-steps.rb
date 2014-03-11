require "rubygems"

#-------------------------
# Local or remote testing
#-------------------------
# Run tests locally
Given(/^I am testing the local environment$/) do
  self.run_cmd = RunCmdWrapper.new
end

# Run tests remotely using ssh
Given(/^I am sshed into the \w*\s*environment$/) do
  run_cmd
end

#-------------------------
# Running external commands
#-------------------------

When(/^I run "(.*?)"$/) do |cmd|
  self.output_lines = run_cmd.run(cmd)
end

# Partial match on command output
Then(/^I should see "(.*)"$/) do |value|
  output_lines.should include value
end

Then(/^I should see regexp "(.*)"$/) do |value|
  output_lines.should match value
end

Then(/^I should see:$/) do |table|
  diff_table table, convert(output_lines.split('\n')), :ignore_extra => true
end

Then(/^I should only see '([^"]*)'$/) do |value|
  output_lines.chomp.should == value
end
