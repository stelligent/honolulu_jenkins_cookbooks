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

# from the jenkins cookbook library, wait until Jenkins is
# back up
extend ::Jenkins::Helper
wait_until_ready!