# cuttingedge: deploy everything to one node, canvas-edge
# No app nodes needed
#
#num_app_nodes = 0
#app_node_prefix = "canvas-edge"
#
#push_app_servers(num_app_nodes, app_node_prefix)

role :app, "canvas-edge.tier2.sfu.ca"
role :db, "canvas-edge.tier2.sfu.ca", :primary => true
set :canvas_url, 'https://canvas-edge.sfu.ca'

set :rails_env, "production"
set :branch, "sfu-develop"

if ENV.has_key?('branch')
  set :branch, ENV['branch']
end
