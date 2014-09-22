require 'capistrano-scm-copy'
set :scm, :copy
set :copy_local_tar, "/usr/local/bin/gtar" if `uname` =~ /Darwin/

set :stage, :staging
set :app_node_prefix, "canvas-as"
set :canvas_url, 'https://canvas-stage.sfu.ca'

role :db, "canvas-ms.tier2.sfu.ca", :primary => true
set :branch, ENV['branch'] || 'sfu-deploy'

namespace :deploy do
  before :started, 'canvas:set_app_nodes'
end

set :default_env, {
  'PATH' => '/usr/pgsql-9.1/bin:$PATH'
}