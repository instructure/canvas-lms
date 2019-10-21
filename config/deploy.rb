# config valid only for Capistrano 3.1
lock '3.5.0'

set :application, 'canvas'
set :repo_url, 'git@github.com:beyond-z/canvas-lms.git'
set :rails_env,     'production'
set :user,          'canvasuser'
set :group,         'canvasadmin'

# IMPORTANT NOTE: on staging, npm is installed using nvm. I mapped the path to npm in the staging.rb config. If we change
# production to have npm installed with nvm, we can use this solution: https://stackoverflow.com/questions/27357023/cap-no-such-file-or-directory-usr-bin-env-npm-although-it-is-really-here

# These settings were pulled from here: https://github.com/sfu/canvas-lms/blob/sfu-develop/config/deploy.rb
# The reason is that canvas:compile_assets requires development gems (parallel-0.5.16) and by default
# the capistrano/bundle lib runs this: 
#     /usr/bin/env bundle install --binstubs /var/canvas/shared/bin --path /var/canvas/shared/bundle --without development test --deployment
# which doesn't install parallel-0.5.16 in the shared/bundle directory.
# 
# This essentially makes Capistrano run the "bundle install" command found in the Canvas Production Start guide
# which doesn't specify the "--without development test" options.
set :bundle_path, "vendor/bundle"
set :bundle_without, "sqlite mysql"
set :bundle_flags,  ""
set :bundle_binstubs, nil 

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/var/canvas'

# We reinstallled npm using nvm. So use the capistrano-nvm gem
# We did this under the "deploy" user since that's the user capistrano runs as.
# We also edited /home/deploy/.bashrc to move the NVM related stuff to the top of 
# the file so that it would run in non-interactive shells (which capistrano deploys use)
set :nvm_node, 'v0.12.14'
set :nvm_map_bins, %w{node npm}

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Turn this on to see why SSH connections are failing:
#set :ssh_options, {
#   verbose: :debug
#}

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


# set the locations that we will look for changed assets to determine whether to precompile
set :assets_dependencies, %w(app/stylesheets app/coffeescripts public/javascripts public/stylesheets app/views/jst spec/javascripts spec/coffeescripts Gemfile.lock config/routes.rb npm-shrinkwrap.json gems/canvas_i18nliner/npm-shrinkwrap.json client_apps/canvas_quizzes/npm-shrinkwrap.json)
#
# Capistrano runs as the deploy user, but Canvas is setup to be owned by another user.
# Rollbacks and cleanups of more than :keep_releases fail with permissions errors. 
# This solves that.
SSHKit.config.command_map[:rm]  = "sudo rm"
SSHKit.config.command_map[:tar]  = "sudo tar"

# Canvas uses it's own precompile assets defined below.
Rake::Task["deploy:compile_assets"].clear_actions
class PrecompileRequired < StandardError;
end

# Since we disable the default "deploy:compile_assets" and overide with the custom 
# "canvas:compile_assets", we also disable the rollback which attempts to put the
# manifest* that rails generates during a normal "deploy:compile_assets" back into place.
Rake::Task["deploy:rollback_assets"].clear_actions

Rake::Task["deploy:restart"].clear_actions

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
      execute :sudo, 'rsync -avr --exclude='*.env*', "#{fetch(:deploy_to)}/config/*", "#{release_path}/config"
      execute :sudo, 'cp -p', "#{fetch(:deploy_to)}/config/.env.local", "#{release_path}"
    end
  end

  before :updated, :copy_config

  desc "Setup permissions on Canvas files in preparation for compile_assets, bundle install, and db:migrate"
  task :setup_permissions do
    on roles(:app) do
      # Needed for rake canvas:compile_assets and db:migrate to work.  It tries to write to production.log
      # and this process runs as the deploy user who is in the canvasadmin group whereas the apache
      # application runs as canvasuser so when logs get rotated they are put in the canvasuser group
      execute :sudo, 'chown -R canvasuser:canvasadmin', release_path.join('log/') 
      execute :sudo, 'chmod -R g+w', release_path.join('log')
      # Set the setgid bit on the log dir so that files created in that dir are owned by the log dir's group by default
      # This is so that when the Rails.logger rotates the files, they maintain the same permissions.
      execute :sudo, 'chmod g+sw', release_path.join('log') 
    end
  end

  before :updated, :setup_permissions

  desc "Clone QTIMigrationTool so that course import and export works"
  task :clone_qtimigrationtool do
    on roles(:app) do
      within release_path do
        execute :git, 'clone', 'https://github.com/instructure/QTIMigrationTool.git', 'vendor/QTIMigrationTool'
        execute :sudo, 'chmod', '+x vendor/QTIMigrationTool/migrate.py'
      end
    end
  end

  desc "Clone data analytics package"
  task :clone_data_analytics do
    on roles(:app) do
      within release_path do
        execute :git, 'clone', '-b master', 'https://github.com/beyond-z/analytics.git', 'gems/plugins/analytics'
      end
    end
  end

  before :updated, :clone_data_analytics
  before :updated, :clone_qtimigrationtool

  desc "Migrate database"
  task :migrate do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          # Have to run predeploy sometimes when pulling in lots of changes b/c
          # predeploy puts in place some dependencies that deploy needs. This was a problem
          # when pulling in updated code from Instructure after an 8 month lapse on 7/27/16
          execute :rake, 'db:migrate:predeploy', '--trace'
          execute :rake, 'db:migrate', '--trace'
        end
      end
    end
  end

  desc "Compile static assets"
  task :compile_assets => :set_compile_assets_vars do
   on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do

          begin

            # This task only actually does the precompile if any files changed that require it.  Otherwise, it copies
            # the file from the previous release.  I used these for inspiration on how to implement:
            # https://coderwall.com/p/aridag/only-precompile-assets-when-necessary-rails-4-capistrano-3
            # http://www.snip2code.com/Snippet/119715/Skip-asset-compilation-in-Capistrano-3-i

            # precompile if this is the first deploy
            raise PrecompileRequired unless fetch(:latest_release)

            info("Comparing asset changes between revision #{fetch(:latest_release_revision)} and #{fetch(:release_revision)} to see if asset precompile is required.")
            fetch(:assets_dependencies).each do |dep|
              if should_compile_assets(dep) then raise PrecompileRequired end
            end

            info("Skipping asset precompile, no asset diff found")

            # NOTE: the commented out command below is for a standard Rails 4+ assets, but our version of Canvas uses an older Rails.
            #
            # copy over all of the assets from the last release
            # execute(:sudo, 'cp -a', latest_release_path.join('public', fetch(:assets_prefix)), release_path.join('public', fetch(:assets_prefix)))
            latest_release_path=fetch(:latest_release_path)
            execute(:sudo, 'cp -a', latest_release_path.join('public/assets'), release_path.join('public'))
            execute(:sudo, 'cp -a', latest_release_path.join('public/doc'), release_path.join('public'))
            execute(:sudo, 'cp -a', latest_release_path.join('client_apps'), release_path) # some things in public/javascripts are symlinked here
            execute(:sudo, 'cp -a', latest_release_path.join('public/javascripts'), release_path.join('public'))
            execute(:sudo, 'cp -a', latest_release_path.join('public/optimized'), release_path.join('public'))
            execute(:sudo, 'cp -a', latest_release_path.join('public/dist'), release_path.join('public'))
            execute(:sudo, 'chmod -R g+w', release_path.join('public')) # For some reason, cp -a is not preserving symlinks in public/javascripts/client_apps.  Let the initializer that fixes it create those links.
                                                                        # Also, it db:migrate fails if it has to create new dirs.  E.g. public/plugins

          rescue PrecompileRequired
           # Note: this took me forever to get going because the "deploy" user that it runs as needs rwx permissions on many
           # files in the config directory, however, we setup those files to only be accessible from canvasuser.
           # The way it works now is that /var/canvas/config has the master copies of the files owned by "canvasadmin:canvasadmin"
           # with their permissions set loosely enough on the group so that compile_assets will work since "deploy" is in the 
           # "canvasadmin" group.
           info("Compiling assets because a file in #{fetch(:assets_dependencies)} changed.")
           execute :npm, 'cache clean -f' # Was getting "npm ERR! cb() never called!".
           # Compile assets runs this in the section labelled: "Making sure node_modules are up to date" of lib/tasks/canvas.rake
           # so I'm commenting this out. Actually, I think the real problem was network connection related where on subsequent
           # installs, the timing happened such that npm packages were downloading with a 200 OK response, but the content was corrupt
           # and so tar unpack failed. On the machine, I ran the following to configure npm to make it more likely that network connection
           # issues wouldn't happen:
           #   npm config set registry http://registry.npmjs.org/
           #   npm config set strict-ssl false
           #   npm set maxsockets 25
           #execute :npm, 'install', '--silent'
           #execute :npm, '-dd install' # print debug log of npm install
           execute :rake, 'canvas:compile_assets', '--trace'
          end
        end
      end
    end
  end

  desc "Set the variables needed by the compile_assets task"
  task :set_compile_assets_vars do
    on roles(:all) do
      # find the most recent release
      set(:latest_release, capture(:ls, '-xr', releases_path).split[1])
      unless fetch(:latest_release).nil? # Can happen on the first deploy to a fresh server
        set(:latest_release_path, releases_path.join(fetch(:latest_release)))

        # store the previous and current git revisions
        set(:release_revision, capture(:cat,release_path.join('REVISION')).strip)
        set(:latest_release_revision, capture(:cat, fetch(:latest_release_path).join('REVISION')).strip)
      end
    end
  end

 def should_compile_assets(path_to_check)
   result = true
   on roles(:all) do
     within repo_path do
       # Canvas compiles assets to the same directory as the source files that are in github.
       # So we can't just look at the local filesystem to compare if files changed
       # So, instead we need to use git to tell if there is a change to the assets.
       #
       # This code reads the REVISION file from the previous release and compares the files in the specified
       # path_to_check to this revision to see if there were any changes.
       #
       debug("Checking #{path_to_check} for asset changes.")
       changed_files = capture(:git,'diff --name-only', "#{fetch(:latest_release_revision)}", "#{fetch(:release_revision)}", '--', "#{path_to_check}")
       result = !changed_files.empty?
       if result then debug("Changed files: #{changed_files}") end
     end
   end
   return result
 end

  desc "Fix ownership on Canvas install directory"
  task :fix_owner do
    on roles(:app) do
      user = fetch :user
      group = fetch :group
      execute :sudo, 'chown -R', "#{group}:#{group}", "#{release_path}"
      execute :sudo, 'chown', "#{user}:#{group}", '/tmp/attachment_fu' # tmp directly used to export grades.
      within release_path do
        execute :sudo, 'chown', "#{user}", "config/*", "Gemfile.lock", "config.ru", "tmp/"
        execute :sudo, 'chmod 440', "config/*.yml"
        execute :sudo, 'chmod 660', "config/google_calendar_auth.json", raise_on_non_zero_exit: false # this file is special b/c the google/api_client needs to write to it when it refreshes the token
      end
    end
  end

  after :migrate, :fix_owner # Note that migrate sometimes needs to update the Gemfile.lock which fails with permissions errors if we lock it down too soon.

  desc 'Restart application'
  task :restart do
    on roles(:app) do
      execute :sudo, 'chmod -R g+w', release_path.join('tmp') # No clue why, but on prod the releases/XXXXX/tmp dir is created but not group writeable.
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

  # NOTE: This is commented out because I just remapped :rm to "sudo rm" so that it works in all cases.
  # I did this after I saw the cleanup of older release fail with the same error.
  #
  # Many files have only rw permissions for the canvasadmin user (not the group) and
  # since the Capistrano deploy user is part of the canvasadmin group,
  # the rollback_cleanup fails when it tries to create a tar archive and then remove the files.  
  # We're adding canvasadmin group permissions to make it work (before the revert b/c otherwise 
  # the release_path would be the release we rolled back to instead of the one we're cleaning up).
  # Note: I also tried running the cleanup_rollback task as sudo, but couldn't figure out how.
  #before :reverting, :fix_rollback_permissions do
  #  on roles(:app) do
  #    execute :sudo, 'chmod -R g+rw', "#{release_path}"
  #  end
  #end

end
