# install all packages from jenkins-server-plugins array to mimic
# previous cookbook's behavior

node['jenkins']['server']['plugins'].each do |plugin|
  jenkins_plugin plugin['name'] do
  	action :uninstall
  end
  jenkins_plugin plugin['name'] do
    version plugin['version'] unless plugin['version'].nil?
    install_deps false
  end
  file "/var/lib/jenkins/plugins/#{plugin['name']}.jpi.pinned" do
  	action :create
  	owner 'jenkins'
  	group 'jenkins'
  	mode '0644'
  end
  ruby_block "Log for #{plugin['name']}" do
  	block do
  		dirll = `/bin/ls -al /var/lib/jenkins/plugins`
  		Chef::Log.warn("Directory for #{plugin['name']}: #{dirll}")
  	end
  	action :create
  end
end

# wait 10 seconds for jenkins to stop responding on its
# listener
execute 'wait for jenkins to restart' do
	command "service jenkins restart;sleep 10"
end

jenkins_command 'version'

ruby_block "Log for post-install_plugins recipe" do
  block do
    dirll = `/bin/ls -al /var/lib/jenkins/plugins`
    Chef::Log.warn("Directory for post-install_plugins plugins: #{dirll}")
  end
  action :create
end