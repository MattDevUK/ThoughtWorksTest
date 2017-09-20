include_recipe "thoughtworks::default"

git "/home/matt/infra-problem" do
  repository "https://github.com/ThoughtWorksInc/infra-problem"
  action :sync
  user "matt"
  group "matt"
  notifies :run,'execute[make_libs]'
  notifies :run, 'execute[make_clean]'
end

execute "make_libs" do
  command "make libs"
  cwd "/home/matt/infra-problem"
  user "matt"
  action :nothing
end

# execute "make_test" do
#   command "make test"
#   cwd "/home/matt/infra-problem"
#   user "matt"
# end

execute "make_clean" do
  command "make clean all"
  cwd "/home/matt/infra-problem"
  user "matt"
  action :nothing
end

# export APP_PORT=8080

# bash 'run_jar' do
#   cwd "/home/matt/infra-problem/build"
#   code <<-EOF
#     java -jar newsfeeds.jar > newsfeeds.log 2>&1 &
#   EOF
# end