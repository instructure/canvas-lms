# encoding: utf-8
require "bundler/capistrano"
set :stages,        %w(production staging testing vm cuttingedge)
require "capistrano/ext/multistage"

set :application,   "canvas"
set :repository,    "git://github.com/sfu/canvas-lms.git"
set :scm,           :git
set :user,          "canvasuser"
set :branch,        "sfu-deploy"
set :deploy_to,     "/var/rails/canvas"
set :use_sudo,      false
set :bundle_dir,    "/mnt/data/gems"
set :bundle_flags,  ""
set :bundle_without,[:sqlite, :test]
set :stats_server,	"stats.tier2.sfu.ca"
default_run_options[:pty] = true

if (ENV.has_key?('gateway') && ENV['gateway'].downcase == "true")
  gateway_user =  ENV['gateway_user'] || ENV['USER']
  set :gateway, "#{gateway_user}@welcome.its.sfu.ca"
  set :stats_server, "stats.its.sfu.ca"
end

if (ENV.has_key?('repository'))
   set :repository, ENV['repository']
end

if (ENV.has_key?('branch'))
   set :branch, ENV['branch']
end

disable_log_formatters;

ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa_canvas")]

namespace :deploy do
	task :start do ; end
	task :stop do ; end

	desc 'Signal Passenger to restart the application.'
 	task :restart, :except => { :no_release => true } do
		run "touch #{current_path}/tmp/restart.txt"
	end

  namespace :web do
    task :disable, :roles => :app do
      on_rollback { rm "#{shared_path}/system/maintenance.html" }
      run "cp /usr/local/canvas/maintenance.html #{shared_path}/system/maintenance.html && chmod 0644 #{shared_path}/system/maintenance.html"
    end
    task :enable, :roles => :app do
      run "rm #{shared_path}/system/maintenance.html"
    end

  end
end

namespace :canvas do
  desc "Set application nodes from config file"
  task :set_app_nodes,  :roles => :db, :only => { :primary => true } do
    stage = fetch :stage
    prefix = fetch :app_node_prefix
    nodes = capture "/usr/local/canvas/bin/getappnodes #{stage}"
    range = *(1..nodes.to_i)
    roles[:app].clear
    range.each do |node|
      parent.role :app, "#{prefix}#{node}.tier2.sfu.ca"
    end
  end

  desc "Create symlink for files folder to mount point"
  task :symlink_canvasfiles do
      target = "mnt/data"
      run "mkdir -p #{latest_release}/mnt/data && ln -s /mnt/data/canvasfiles #{latest_release}/#{target}/canvasfiles"
  end

  desc "Copy config files from /mnt/data/canvasconfig/config"
  task :copy_config do
    run "sudo CANVASDIR=#{latest_release} /etc/init.d/canvasconfig start"
  end

  desc "Clone QTIMigrationTool"
  task :clone_qtimigrationtool do
    run "cd #{latest_release}/vendor && git clone https://github.com/instructure/QTIMigrationTool.git QTIMigrationTool && chmod +x QTIMigrationTool/migrate.py"
  end

  desc "Compile static assets"
  task :compile_assets do
    # On remote: bundle exec rake canvas:compile_assets
    run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} canvas:compile_assets[false]"
    run "cd #{latest_release} && chown -R canvasuser:canvasuser ."
  end

  desc "Run predeploy db migration task"
  task "migrate_predeploy", :roles => :db, :only => { :primary => true } do
    run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} db:migrate:predeploy"
  end

  desc "Load new notification types"
  task :load_notifications, :roles => :db, :only => { :primary => true } do
    # On remote: RAILS_ENV=production bundle exec rake db:load_notifications
    run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} db:load_notifications"
  end

  desc "Restart delayed jobs workers"
  task :restart_jobs, :roles => :db do
    run "sudo /etc/init.d/canvas_init restart"
  end

  desc "Log the deploy to graphite"
  task :log_deploy do
    ts = Time.now.to_i
    cmd = "echo 'stats.canvas.#{stage}.deploys 1 #{ts}' | nc #{stats_server} 2003"
    puts run_locally cmd
  end

  desc "Tasks that run before create_symlink"
  task :before_create_symlink do
    copy_config
    migrate_predeploy
    clone_qtimigrationtool
    symlink_canvasfiles
    compile_assets
  end

  desc "Tasks that run after create_symlink"
  task :after_create_symlink do
    load_notifications
    deploy.migrate
  end

  desc "Tasks that run after the deploy completes"
  task :after_deploy do
    restart_jobs
    log_deploy
  end

  desc "Ping the canvas server to actually restart the app"
  task :ping do
    system "curl -m 10 --silent #{fetch(:canvas_url)}/sfu/api/v1/terms/current"
  end
end

before("deploy:create_symlink", "canvas:before_create_symlink")
after("deploy:create_symlink", "canvas:after_create_symlink")
after("deploy:restart", "canvas:ping")
after(:deploy, "canvas:after_deploy")
after(:deploy, "deploy:cleanup")
