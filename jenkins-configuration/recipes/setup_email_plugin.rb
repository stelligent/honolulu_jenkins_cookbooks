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

# lifted from http://blog.open-tribute.org/2013/09/how-to-get-your-ses-smtp-password-from.html
# based on information at http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html
# on generating SES creds from existing IAM user creds
require 'openssl'
require 'base64'

sha256 = OpenSSL::Digest::Digest.new('sha256')
secret_key = node["pipeline"]["email"]["secret_key"]
message = "SendRawEmail" # needs to be the string SendRawEmail
version = "\x02" # needs to be 0x2

signature = OpenSSL::HMAC.digest(sha256, secret_key, message)
verSignature = version + signature

smtp_password = Base64.encode64(verSignature)


# for our scripts later to be able to know this ohai resource
file "/etc/admin_email" do
  owner "root"
  group "root"
  content node["pipeline"]["email"]["admin_email_address"]
  mode 0644
end

template "/etc/sysconfig/jenkins" do
  owner "root"
  group "root"
  source "jenkins.erb"
end

# we probably do this somewhere else in this cookbook, but just in case, we restart here so changes take effect
service "jenkins" do
  action :restart
end

template "/var/lib/jenkins/hudson.plugins.emailext.ExtendedEmailPublisher.xml" do
  source "hudson.plugins.emailext.ExtendedEmailPublisher.xml.erb"
  mode 0644
  owner "jenkins"
  group "jenkins"
  variables(
    { 
      :domain         => node["pipeline"]["global_vars"]["domain"],
      :jenkins_url    => "pipelinedemo.#{node['pipeline']['global_vars']['domain']}",
      :email_username => node["pipeline"]["email"]["username"],
      :email_password => smtp_password,
      :email_address  => node["pipeline"]["email"]["admin_email_address"],
      :smtp_server    => node["pipeline"]["email"]["smtp_server"],
      :smtp_port      => node["pipeline"]["email"]["smtp_port"]
    }
  )
end
