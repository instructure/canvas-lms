require "bundler/capistrano"
set :stages,        %w(production staging testing vm)
set :default_stage, "testing"
require "capistrano/ext/multistage"

set :application,   "canvas"
set :repository,    "git://github.com/sfu/canvas-lms.git"
set :scm,           :git
set :user,          "canvasuser"
set :branch,        "sfu-deploy"
set :deploy_via,    :remote_cache
set :deploy_to,     "/var/rails/canvas"
set :use_sudo,      false
set :deploy_env,    "production"
set :bundle_dir,    "/mnt/data/gems"
set :bundle_without, []
set :stats_server,	"stats.tier2.sfu.ca"
default_run_options[:pty] = true

def push_app_servers(num_app_nodes, app_node_prefix)
  range = *(1..num_app_nodes)
  range.each { |x| role :app, "#{app_node_prefix}#{x}.tier2.sfu.ca" }
end

def is_hotfix?
  ENV.has_key?('hotfix') && ENV['hotfix'].downcase == "true"
end

if (ENV.has_key?('gateway') && ENV['gateway'].downcase == "true")
  set :gateway, "welcome.its.sfu.ca"
  set :stats_server, "stats.its.sfu.ca"
end

disable_log_formatters;

ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa_canvas")]

namespace :deploy do
	task :start do ; end
	task :stop do ; end
	desc 'Signal Passenger to restart the application.'
 	task :restart, :except => { :no_release => true } do
    puts "Signal Passenger to restart: touching #{release_path}/tmp/restart.txt"
		run "touch #{release_path}/tmp/restart.txt"
    # run "sudo /etc/init.d/httpd restart"
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

    desc "Create symlink for files folder to mount point"
    task :symlink_canvasfiles do
        target = "mnt/data"
        run "mkdir -p #{latest_release}/mnt/data && ln -s /mnt/data/canvasfiles #{latest_release}/#{target}/canvasfiles"
    end

    desc "Copy config files from /mnt/data/canvasconfig/config"
    task :copy_config do
      run "sudo /etc/init.d/canvasconfig start"
    end

    desc "Clone QTIMigrationTool"
    task :clone_qtimigrationtool do
      run "cd #{latest_release}/vendor && git clone https://github.com/instructure/QTIMigrationTool.git QTIMigrationTool && chmod +x QTIMigrationTool/migrate.py"
    end

    desc "Compile static assets"
    task :compile_assets, :on_error => :continue do
      # On remote: bundle exec rake canvas:compile_assets
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} canvas:compile_assets[false] --quiet"
      run "cd #{latest_release} && chown -R canvasuser:canvasuser ."
    end

    desc "Load new notification types"
    task :load_notifications, :roles => :db, :only => { :primary => true } do
      # On remote: RAILS_ENV=production bundle exec rake db:load_notifications
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} db:load_notifications --quiet"
    end

    desc "Restart delayed jobs workers"
    task :restart_jobs, :roles => :db, :only => { :primary => true } do
      run "sudo /etc/init.d/canvas_init restart"
    end

    desc "Log the deploy to graphite"
    task :log_deploy do
      ts = Time.now.to_i
      cmd = "echo 'stats.canvas.#{stage}.deploys 1 #{ts}' | nc #{stats_server} 2003"
      puts cmd
      puts run_locally cmd
    end

    desc "Post-update commands"
    task :update_remote do
      copy_config
      clone_qtimigrationtool
      deploy.migrate unless is_hotfix?
      load_notifications unless is_hotfix?
      restart_jobs
      log_deploy
    end

end

before(:deploy, "deploy:web:disable") unless is_hotfix?
before("deploy:create_symlink", "canvas:symlink_canvasfiles")
before("deploy:create_symlink", "canvas:compile_assets")
before("deploy:create_symlink", "canvas:update_remote")

after(:deploy, "deploy:cleanup")
after(:deploy, "deploy:web:enable") unless is_hotfix?
