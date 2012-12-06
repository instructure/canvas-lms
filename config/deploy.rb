require "bundler/capistrano"
# set :stages,        %w(production dev)
# set :default_stage, "production"
# require "capistrano/ext/multistage"

set :application,   "canvas"
set :repository,    "git@github.com:grahamb/canvas-lms.git"
set :scm,           :git
set :user,          "canvasuser"
set :branch,        "dev"
set :deploy_via,    :remote_cache
set :deploy_to,     "/var/rails/canvas"
set :use_sudo,      false
set :deploy_env,    "production"
ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa_canvas")]

role :app, "canvas-at1.tier2.sfu.ca", "canvas-at2.tier2.sfu.ca", "canvas-at3.tier2.sfu.ca"
role :db,  "canvas-mt.tier2.sfu.ca"

task :latest_release, :roles => [:db, :app] do
  puts "#{latest_release}"
end
