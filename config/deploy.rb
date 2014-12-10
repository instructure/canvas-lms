# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'canvas'
set :repo_url, 'git@github.com:beyond-z/canvas-lms.git'
set :rails_env,     'production'
set :user,          'canvasuser'
set :group,         'canvasadmin'

# These settings were pulled from here: https://github.com/sfu/canvas-lms/blob/sfu-develop/config/deploy.rb
# The reason is that canvas:compile_assets requires development gems (parallel-0.5.16) and by default
# the capistrano/bundle lib runs this: 
#     /usr/bin/env bundle install --binstubs /var/canvas/shared/bin --path /var/canvas/shared/bundle --without development test --deployment
# which doesn't install parallel-0.5.16 in the shared/bundle directory.
# 
# This essentially makes Capistrano run the "bundle install" command found in the Canvas Production Start guide
# which doesn't specify the "--without development test" options.
set :bundle_path, "vendor/bundle"
set :bundle_without, nil
set :bundle_flags,  ""

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/var/canvas'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
#set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# Oh nelly, DO NOT add the "config" dir in here.  Symlinked config files don't work
# for core ruby config, like boot.rb when it sets RAILS_ROOT.  You'll get Rack loading
# errors when it can't find files (e.g. lib/canvas_logger).  This is the reason that
# configs are copied over in the copy_configs task.
set :linked_dirs, %w{log tmp/pids public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Canvas uses it's own precompile assets defined below.
Rake::Task["deploy:compile_assets"].clear_actions

# Since we disable the default "deploy:compile_assets" and overide with the custom 
# "canvas:compile_assets", we also disable the rollback which attempts to put the
# manifest* that rails generates during a normal "deploy:compile_assets" back into place.
Rake::Task["deploy:rollback_assets"].clear_actions

# Disable for now until we get the basic Cap deploy and rollback going for code and can really test this.
Rake::Task["deploy:migrate"].clear_actions

namespace :deploy do

  # TODO: change this to tag the git branch. 
  #desc 'Update application code'
  #task :update do
  #  on roles(:app) do |host|
  #    within fetch(:deploy_to) do
  #      execute :git, 'pull', 'origin', fetch(:branch)
  #    end
  #  end
  #end

  desc "Copy config files from <deploy_to>/config to the release directory"
  task :copy_config do
    on roles(:app) do
      execute :sudo, 'cp -rp', "#{fetch(:deploy_to)}/config/*", "#{release_path}/config"
    end
  end

  before :updated, :copy_config

  desc "Clone QTIMigrationTool so that course import and export works"
  task :clone_qtimigrationtool do
    on roles(:app) do
      within release_path do
        execute :git, 'clone', 'https://github.com/instructure/QTIMigrationTool.git', 'vendor/QTIMigrationTool'
        execute :sudo, 'chmod', '+x vendor/QTIMigrationTool/migrate.py'
      end
    end
  end

  before :updated, :clone_qtimigrationtool

  desc "Migrate database"
  task :migrate do
    # TODO: need to get this working, but for now we're just focusing on getting a code deploy and rollback flow going
  end

  desc "Install node dependencies"
  task :npm_install do
    on roles(:app) do
      within release_path do
        execute :npm, 'install', '--silent'
      end
    end
  end


  # TODO: This takes forever, see if we can copy the assets from the last deploy if nothing has changed.
  # Try this: https://coderwall.com/p/aridag/only-precompile-assets-when-necessary-rails-4-capistrano-3
  # Another way to try this: http://www.snip2code.com/Snippet/119715/Skip-asset-compilation-in-Capistrano-3-i
  desc "Compile static assets"
  task :compile_assets => :npm_install do
   on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # Note: this took me forever to get going because the "deploy" user that it runs as needs rwx permissions on many
          # files in the config directory, however, we setup those files to only be accessible from canvasuser.
          # The way it works now is that /var/canvas/config has the master copies of the files owned by "canvasadmin:canvasadmin"
          # with their permissions set loosely enough on the group so that compile_assets will work since "deploy" is in the 
          # "canvasadmin" group.
          #execute :rake, 'canvas:compile_assets --trace'
          execute :rake, 'canvas:compile_assets'
        end
      end
    end
  end

  desc "Fix ownership on Canvas install directory"
  task :fix_owner do
    on roles(:app) do
      user = fetch :user
      group = fetch :group
      execute :sudo, 'chown -R', "#{group}:#{group}", "#{release_path}"
      within release_path do
        execute :sudo, 'chown', "#{user}", "config/*", "Gemfile.lock", "config.ru"
        execute :sudo, 'chmod 400', "config/*.yml"
      end
    end
  end

  after :compile_assets, :fix_owner

  desc 'Restart application'
  task :restart do
    on roles(:app) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :published, :restart

  #after :restart, :clear_cache do
  #  on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
  #  end
  #end

  # Note: see this for a way to run start, stop, or restart: https://github.com/grahamb/capistrano-canvas/blob/master/lib/capistrano/tasks/canvas.rake
  namespace :delayed_jobs do
    %w[start stop restart].each do |command|
      desc "#{command} the delayed_jobs processor"
      task command do
        on roles(:db) do
          execute :sudo, '/etc/init.d/canvas_init', "#{command}"
        end
      end
    end
  end

  after :published, 'deploy:delayed_jobs:restart'

  # Many files have only rw permissions for the canvasadmin user (not the group) and
  # since the Capistrano deploy user is part of the canvasadmin group,
  # the rollback_cleanup fails when it tries to create a tar archive and then remove the files.  
  # We're adding canvasadmin group permissions to make it work (before the revert b/c otherwise 
  # the release_path would be the release we rolled back to instead of the one we're cleaning up).
  # Note: I also tried running the cleanup_rollback task as sudo, but couldn't figure out how.
  before :reverting, :fix_rollback_permissions do
    on roles(:app) do
      execute :sudo, 'chmod -R g+rw', "#{release_path}"
    end
  end

end
