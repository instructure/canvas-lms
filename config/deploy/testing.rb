set :app_node_prefix, "canvas-at"
set :canvas_url, 'https://canvas-test.sfu.ca'

role :db, "canvas-mt.tier2.sfu.ca", :primary => true

set :rails_env, "production"
set :branch, "sfu-develop"

if ENV.has_key?('branch')
  set :branch, ENV['branch']
end

on :start, "canvas:set_app_nodes"