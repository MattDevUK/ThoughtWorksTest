include_recipe "thoughtworks::default"

bash 'run_jar' do
  cwd "/home/matt/infra-problem/build"
  code <<-EOF
    java -jar newsfeeds.jar > newsfeeds.log 2>&1 &
  EOF
end