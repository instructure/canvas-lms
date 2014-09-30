require 'capistrano-scm-copy'
set :scm, :copy
set :copy_local_tar, "/usr/local/bin/gtar" if `uname` =~ /Darwin/

set :stage, :cuttingedge
role :app, "canvas-edge.tier2.sfu.ca"
role :db, "canvas-edge.tier2.sfu.ca", :primary => true
set :canvas_url, 'https://canvas-edge.sfu.ca'

set :rails_env, "production"
set :branch, ENV['branch'] || 'edge'

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}