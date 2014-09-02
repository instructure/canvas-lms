set :stage, :production
role :db,  %w{canvas-mp1.tier2.sfu.ca canvas-mp2.tier2.sfu.ca}

on :start, 'canvas:set_app_nodes'

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}