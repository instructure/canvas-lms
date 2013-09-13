num_app_nodes = 10
app_node_prefix = "canvas-ap"
set :canvas_url, 'https://canvas.sfu.ca'

push_app_servers(num_app_nodes, app_node_prefix)
role :db, "canvas-mp.tier2.sfu.ca", :primary => true
role :db, "canvas-mp2.tier2.sfu.ca"

set :rails_env, "production"
