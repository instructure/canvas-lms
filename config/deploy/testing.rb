set :stage, :testing
set :app_node_prefix, "canvas-at"
set :canvas_url, 'https://canvas-test.sfu.ca'

role :app, %w{canvas-at1.tier2.sfu.ca canvas-at2.tier2.sfu.ca canvas-at3.tier2.sfu.ca}
role :db,  %w{canvas-mt.tier2.sfu.ca}
set :branch, ENV['branch'] || 'sfu-develop'

namespace :deploy do
  before :started, 'canvas:set_app_nodes'
end

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}