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
  notifies :run,'execute[make_libs]', :immediately
end

execute "make_libs" do
  command "make libs"
  cwd "#{Chef::Config['file_cache_path']}/infra-problem"
  action :nothing
  notifies :run, 'execute[make_clean]', :immediately
end

execute "make_clean" do
  command "make clean all"
  cwd "#{Chef::Config['file_cache_path']}/infra-problem"
  action :nothing
  notifies :create, "remote_file[Deploy #{service_name}]"
end

remote_file "Deploy #{service_name}" do
  path "#{appHome}/#{service_name}/#{service_name}.jar"
  source "file:///#{Chef::Config['file_cache_path']}/infra-problem/build/#{service_name}.jar"
  action :nothing
  notifies :restart, "service[#{service_name}]", :delayed
end

# execute "make_test" do
#   command "make test"
#   cwd "/home/matt/infra-problem"
#   user "matt"
#   action :nothing
# end

if service_name == "front-end"
  execute "serve" do
    command "./serve.py > serve.log 2>&1 &"
    cwd "#{Chef::Config['file_cache_path']}/infra-problem/front-end/public"
  end
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