#
# Cookbook Name:: thoughtworks
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "java::default"
#include_recipe "lein::default"

remote_file "/usr/local/bin/lein" do
  source "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
  mode "755"
  owner "root"
  group "root"
  backup false
end

execute "install_leiningen" do
  command "lein version"
  user   node[:lein][:user]
  group  node[:lein][:group]
  environment ({"HOME" => node[:lein][:home], "HTTP_CLIENT" => 'curl --insecure -f -L -o'})
end

include_recipe "poise-python"

git "/home/matt/infra-problem" do
  repository "https://github.com/ThoughtWorksInc/infra-problem"
  action :checkout
  user "matt"
  group "matt"
end

package "build-essential" do
  action :install
end

execute "make_test" do
  command "make test"
  cwd "/home/matt/infra-problem"
  user "matt"
end

execute "make_libs" do
  command "make libs"
  cwd "/home/matt/infra-problem"
  user "matt"
end

execute "make_clean" do
  command "make clean all"
  cwd "/home/matt/infra-problem"
  user "matt"
end