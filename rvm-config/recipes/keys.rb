# rvm installer now requires gpg keys be present if gpg
# is present on a system

# this should get added to fnichol/chef-rvm at some point, see
# https://github.com/fnichol/chef-rvm/issues/278

cookbook_file '/etc/pki/rvm-keys.asc' do
	owner 'root'
	group 'root'
	mode '0644'
	source 'rvm-keys.asc'
	action :create
end

execute 'Add system gpg keys' do
	command 'gpg --import /etc/pki/rvm-keys.asc'
	only_if 'which gpg'
end

execute 'Add jenkins user gpg keys' do	
	command 'gpg --homedir /var/lib/jenkins/.gnupg --import /etc/pki/rvm-keys.asc'
	only_if 'which gpg'
	user 'jenkins'
end