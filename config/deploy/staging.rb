num_app_nodes = 3
app_node_prefix = "canvas-as"

push_app_servers(num_app_nodes, app_node_prefix)
role :db, "canvas-ms.tier2.sfu.ca", :primary => true

set :rails_env, "production"
set :branch, "sfu-develop"

if ENV.has_key?('branch')
  set :branch, ENV['branch']
end