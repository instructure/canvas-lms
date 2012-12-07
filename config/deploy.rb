require "bundler/capistrano"
# set :stages,        %w(production dev)
# set :default_stage, "production"
# require "capistrano/ext/multistage"

set :application,   "canvas"
set :repository,    "git://github.com/grahamb/canvas-lms.git"
set :scm,           :git
set :user,          "canvasuser"
set :branch,        "dev"
set :deploy_via,    :remote_cache
set :deploy_to,     "/var/rails/canvas"
set :use_sudo,      false
set :deploy_env,    "production"
ssh_options[:forward_agent] = true
ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa_canvas")]

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart do; end
end

namespace :canvas do

    desc "Create symlink for files folder to mount point"
    task :symlink_canvasdata do
        target = "mnt/data"
        run "mkdir -p #{latest_release}/mnt/data && ln -s /mnt/data/canvasfiles #{latest_release}/#{target}/canvasfiles"
    end

    desc "Compile static assets"
    task :compile_assets, :on_error => :continue do
      # On remote: bundle exec rake canvas:compile_assets
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} canvas:compile_assets"
      run "cd #{latest_release} && chown -R canvasuser:canvasuser ."
    end

    desc "Load new notification types"
    task :load_notifications, :roles => :db, :only => { :primary => true } do
      # On remote: RAILS_ENV=production bundle exec rake db:load_notifications
      run "cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} db:load_notifications --quiet"
    end

    desc "Restart delayed jobs workers"
    task :restart_jobs, :on_error => :continue do
      run "/etc/init.d/canvas_init restart"
    end

    desc "Post-update commands"
    task :update_remote do
      # deploy.migrate
      # load_notifications
      restart_jobs
      puts "\x1b[42m\x1b[1;37m Deploy complete!  \x1b[0m"
    end

end

after(:deploy, "deploy:cleanup")
before("deploy:restart", "canvas:files_symlink")
before("deploy:restart", "canvas:compile_assets")


