include_recipe "thoughtworks::default"

execute "serve" do
  command "serve.py"
  cwd "/home/matt/infra-problem/front-end/public"
  user "matt"
end

bash 'run_jar' do
  cwd "/home/matt/infra-problem/build"
  code <<-EOF
    java -jar front-end.jar > front-end.log 2>&1 &
  EOF
end