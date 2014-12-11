# rvm installer now requires gpg keys be present if gpg
# is present on a system

# this should get added to fnichol/chef-rvm at some point, see
# https://github.com/fnichol/chef-rvm/issues/278

execute 'Adding gpg keys' do
	command 'gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 BF04FF17'
	only_if 'which gpg'
end