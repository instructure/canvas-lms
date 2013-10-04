set :app_node_prefix = "canvas-as"
set :canvas_url, 'https://canvas-stage.sfu.ca'

role :db, "canvas-ms.tier2.sfu.ca", :primary => true

set :rails_env, "production"
set :branch, "sfu-develop"

if ENV.has_key?('branch')
  set :branch, ENV['branch']
end

on :start, "canvas:set_app_nodes"