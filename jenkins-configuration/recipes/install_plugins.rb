# install all packages from jenkins-server-plugins array to mimic
# previous cookbook's behavior

node['jenkins']['server']['plugins'].each do |plugin|
  jenkins_plugin plugin['name'] do
    version plugin['version'] unless plugin['version'].nil?
    install_deps false
  end
end
