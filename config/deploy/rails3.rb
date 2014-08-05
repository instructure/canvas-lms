# rails3: deploy everything to one node, canvas-rails3
# No app nodes needed
#
#num_app_nodes = 0
#app_node_prefix = "canvas-rails3"
#
#push_app_servers(num_app_nodes, app_node_prefix)

set :copy_local_tar, "/usr/local/bin/gtar" if `uname` =~ /Darwin/
set :scm, :none
set :repository, "."
set :deploy_via, :copy
set :copy_exclude, [".git", "vendor/bundle"]

role :app, "canvas-rails3.tier2.sfu.ca"
role :db, "canvas-rails3.tier2.sfu.ca", :primary => true
set :canvas_url, 'https://canvas-rails3.sfu.ca'

set :rails_env, "production"
set :branch, "sfu-develop"

if ENV.has_key?('branch')
  set :branch, ENV['branch']
end

namespace :canvas do
  desc "Create RAILS3 file"
  task "touch_the_third_rail" do
  run "touch #{latest_release}/config/RAILS3"
  end
end

before("bundle:install", "canvas:touch_the_third_rail")