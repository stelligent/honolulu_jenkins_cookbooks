cookbook_file "script to install Firefox" do
  source "gtk-firefox.sh"
  path "/tmp/gtk-firefox.sh"
end
 
bash "install_firefox" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    . /tmp/gtk-firefox.sh
  EOH
end

