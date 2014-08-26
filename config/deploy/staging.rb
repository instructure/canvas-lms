set :stage, :staging
set :app_node_prefix, "canvas-as"
set :canvas_url, 'https://canvas-stage.sfu.ca'

role :db,  %w{canvas-ms.tier2.sfu.ca}
set :branch, ENV['branch'] || 'sfu-develop'
# on :start, 'canvas:set_app_nodes'