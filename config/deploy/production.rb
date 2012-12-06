role :app, "canvas-ap1.tier2.sfu.ca", "canvas-ap2.tier2.sfu.ca", "canvas-ap3.tier2.sfu.ca"
role :db, "canvas-mp.tier2.sfu.ca", :primary => true

set :rails_env, "production"