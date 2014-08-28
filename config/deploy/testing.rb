set :stage, :testing
set :app_node_prefix, "canvas-at"
set :canvas_url, 'https://canvas-test.sfu.ca'

role :db,  %w{canvas-mt.tier2.sfu.ca}
set :branch, ENV['branch'] || 'sfu-develop'
on :start, 'canvas:set_app_nodes'

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}