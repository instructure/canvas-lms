set :stage, :production
role :db,  %w{canvas-mp1.tier2.sfu.ca canvas-mp2.tier2.sfu.ca}

# on :start, 'canvas:set_app_nodes'