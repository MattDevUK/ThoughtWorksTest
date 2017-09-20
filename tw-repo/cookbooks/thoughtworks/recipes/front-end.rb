include_recipe "thoughtworks::default"

service_name = node['thoughtworks']['service_name']
appHome = node['thoughtworks']['appHome']

directory "#{appHome}" do
  action :create
  recursive true
end

service "#{service_name}" do
  action :nothing
end

directory "#{appHome}/#{service_name}" do
  action :create
  recursive true
end

git "#{Chef::Config['file_cache_path']}/infra-problem" do
  repository "https://github.com/ThoughtWorksInc/infra-problem"
  action :sync
  notifies :run,'execute[make_libs]'
  notifies :run, 'execute[make_clean]'
end

execute "make_libs" do
  command "make libs"
  cwd "/home/matt/infra-problem"
  action :nothing
end

execute "make_clean" do
  command "make clean all"
  cwd "/home/matt/infra-problem"
  action :nothing
end

remote_file "Deploy #{service_name}" do
  path "#{appHome}/#{service_name}/#{service_name}.jar"
  source "file:///#{Chef::Config['file_cache_path']}/infra-problem/build/#{service_name}.jar"
  not_if { File.exists?("#{appHome}/#{service_name}/#{service_name}.jar") }
  action :create
  notifies :restart, "service[#{service_name}]", :delayed
end

# execute "make_test" do
#   command "make test"
#   cwd "/home/matt/infra-problem"
#   user "matt"
#   action :nothing
# end

execute "serve" do
  command "./serve.py"
  cwd "#{appHome}/front-end/public"
end

template "/etc/init.d/#{service_name}" do
	source "jar_service.erb"
	owner  "root"
	group  "root"
	mode   "0755"
	action :create
	notifies :enable, "service[#{service_name}]", :immediately
	notifies :restart, "service[#{service_name}]", :delayed
	variables(
	  :appHome => appHome,
	  :appName => service_name
	)
end