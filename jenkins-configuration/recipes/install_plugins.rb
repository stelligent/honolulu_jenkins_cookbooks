# install all packages from jenkins-server-plugins array to mimic
# previous cookbook's behavior

node['jenkins']['server']['plugins'].each do |plugin|
  jenkins_plugin plugin['name'] do
    version plugin['version'] unless plugin['version'].nil?
    install_deps false
  end
end

# wait 10 seconds for jenkins to stop responding on its
# listener
execute 'wait for jenkins to restart' do
	command "service jenkins restart;sleep 10"
end

node.set['jenkins']['executor']['timeout'] ||= 120

jenkins_command 'version'