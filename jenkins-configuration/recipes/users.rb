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

jenkins_url = "http://localhost:8080"
# jenkins_home = '/var/lib/jenkins'


#classloader problem with asking groovy plugin to do stuff
service "jenkins" do
  action :restart
end

jenkins_command 'start job-seed' do
  command 'build job-seed'
end

cookbook_file "script to add Jenkins global variables" do
  source "create_user.groovy"
  path "/tmp/create_user.groovy"
end

node.set['jenkins']['master']['endpoint'] = jenkins_url

users = node["pipeline"]["users"].collect {|user| "#{user[0]} #{user[1]} #{user[2]}"}.each do |args|
  jenkins_command "add global variables" do
    command "groovy /tmp/create_user.groovy #{args}"
  end
end
