set :stage, :staging
set :app_node_prefix, "canvas-as"
set :canvas_url, 'https://canvas-stage.sfu.ca'

# role :app, %w{canvas-as1.tier2.sfu.ca canvas-as2.tier2.sfu.ca canvas-as3.tier2.sfu.ca}
role :app, "canvas-as1.tier2.sfu.ca"
role :app, "canvas-as2.tier2.sfu.ca"
role :app, "canvas-as3.tier2.sfu.ca"
role :db, "canvas-ms.tier2.sfu.ca", :primary => true
set :branch, ENV['branch'] || 'sfu-develop'

namespace :deploy do
  before :started, 'canvas:set_app_nodes'
end

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}