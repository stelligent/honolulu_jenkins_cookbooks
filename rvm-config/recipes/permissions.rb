# AWS OpsWorks has restrictive permissions on the /var/lib/aws and /var/lib/aws/opsworks
# directories which makes it impossible for an unpriv user to read scripts in
# /var/lib/aws/opsworks/cache.stage2/ to execute them, which breaks rvm user installs
# see provider_rvm_installation.rb in the rvm cookbook for implementation details

directory '/var/lib/aws' do
	mode '0751'
end

directory '/var/lib/aws/opsworks' do
	mode '0751'
end