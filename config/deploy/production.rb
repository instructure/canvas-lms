set :app_node_prefix = "canvas-ap"
set :canvas_url, 'https://canvas.sfu.ca'

role :db, "canvas-mp.tier2.sfu.ca", :primary => true
role :db, "canvas-mp2.tier2.sfu.ca"
set :rails_env, "production"
on :start, "canvas:set_app_nodes"