bash "setup system rubies" do
  # use mount command and S3 bucket for azn lnx 2014.09 ruby build
  # also faster than building
  code "/usr/local/rvm/bin/rvm mount -r https://s3.amazonaws.com/StelligentLabsResources/rvm/rubies/amazon/ruby-1.9.3-p551.tar.bz2 --verify-downloads 2"
end

bash "setup user rubies" do
  # use mount command and S3 bucket for azn lnx 2014.09 ruby build
  # also faster than building
  cwd '/var/lib/jenkins'
  code <<-EOH
  export USER=jenkins
  export USERNAME=jenkins
  export HOME=/var/lib/jenkins
  export LOGNAME=jenkins
  . .rvmrc
  . .profile
  env
  ./.rvm/bin/rvm mount -r https://s3.amazonaws.com/StelligentLabsResources/rvm/rubies/amazon/ruby-1.9.3-p551.tar.bz2 --verify-downloads 2
  ./.rvm/bin/rvm --default use 1.9.3
  EOH
  user 'jenkins'
end

rvm_default_ruby 'system' do
	ruby_string '1.9.3'
end

# seems broken with non-system user
if false
rvm_default_ruby 'jenkins'	do
	ruby_string '1.9.3'
	user 'jenkins'
end
end