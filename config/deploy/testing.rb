num_app_nodes = 3
app_node_prefix = "canvas-at"
set :canvas_url, 'https://canvas-test.sfu.ca'

push_app_servers(num_app_nodes, app_node_prefix)
role :db, "canvas-mt.tier2.sfu.ca", :primary => true

set :rails_env, "production"
set :branch, "sfu-develop"

if ENV.has_key?('branch')
  set :branch, ENV['branch']
end