set :stage, :production
role :db,  %w{canvas-mp1.tier2.sfu.ca canvas-mp2.tier2.sfu.ca}

namespace :deploy do
  before :started, 'canvas:set_app_nodes'
end

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}
