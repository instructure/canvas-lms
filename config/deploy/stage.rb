role :app, "canvas-as1.tier2.sfu.ca", "canvas-as2.tier2.sfu.ca", "canvas-as3.tier2.sfu.ca"
role :db, "canvas-ms.tier2.sfu.ca", :primary => true

set :rails_env, "production"