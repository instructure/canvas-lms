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
set :bundle_binstubs, nil 

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

# set the locations that we will look for changed assets to determine whether to precompile
set :assets_dependencies, %w(app/stylesheets public/javascripts public/stylesheets spec/javascripts Gemfile.lock config/routes.rb)
#
# Capistrano runs as the deploy user, but Canvas is setup to be owned by another user.
# Rollbacks and cleanups of more than :keep_releases fail with permissions errors. 
# This solves that.
SSHKit.config.command_map[:rm]  = "sudo rm"

# Canvas uses it's own precompile assets defined below.
Rake::Task["deploy:compile_assets"].clear_actions
class PrecompileRequired < StandardError;
end

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

  # TODO: This takes forever, see if we can copy the assets from the last deploy if nothing has changed.
  # Try this: https://coderwall.com/p/aridag/only-precompile-assets-when-necessary-rails-4-capistrano-3
  # Another way to try this: http://www.snip2code.com/Snippet/119715/Skip-asset-compilation-in-Capistrano-3-i
  desc "Compile static assets"
  task :compile_assets => :set_compile_assets_vars do
   on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          begin
            # precompile if this is the first deploy
            raise PrecompileRequired unless fetch(:latest_release)

            info("Comparing asset changes between revision #{fetch(:latest_release_revision)} and #{fetch(:release_revision)}")
            fetch(:assets_dependencies).each do |dep|
              #########
              ########
              #BTODO: THIS DOESN'T WORK.  this invokes all the checks in parallel and continues
              # see: http://stackoverflow.com/questions/12379026/how-do-i-execute-rake-tasks-with-arguments-multiple-times
              # I think that I should use a method instead of a task?
              
              # Raises PrecompileRequired if any of the files in this directory have changed in git.
              invoke("deploy:check_compile_assets", "#{dep}")
              ###########
            end

            info("Skipping asset precompile, no asset diff found")

            # NOTE: the commented out command below is for a standard Rails 4+ assets, but our version of Canvas uses an older Rails.
            #
            # copy over all of the assets from the last release
            # execute(:sudo, 'cp -r', latest_release_path.join('public', fetch(:assets_prefix)), release_path.join('public', fetch(:assets_prefix)))
            latest_release_path=fetch(:latest_release_path)
            execute(:sudo, 'cp -r', latest_release_path.join('public/assets'), release_path.join('public/assets'))
            execute(:sudo, 'cp -r', latest_release_path.join('public/doc'), release_path.join('public/doc'))
            execute(:sudo, 'cp -r', latest_release_path.join('public/javascripts'), release_path.join('public/javascripts'))
            execute(:sudo, 'cp -r', latest_release_path.join('public/optimized'), release_path.join('public/optimized'))
            execute(:sudo, 'cp -r', latest_release_path.join('public/stylesheets_compiled'), release_path.join('public/stylesheets_compiled'))

          rescue PrecompileRequired
            # Note: this took me forever to get going because the "deploy" user that it runs as needs rwx permissions on many
            # files in the config directory, however, we setup those files to only be accessible from canvasuser.
            # The way it works now is that /var/canvas/config has the master copies of the files owned by "canvasadmin:canvasadmin"
            # with their permissions set loosely enough on the group so that compile_assets will work since "deploy" is in the 
            # "canvasadmin" group.
            info("Compiling assets because a file in #{fetch(:assets_dependencies)} changed.")
            execute :npm, 'install', '--silent'
            #execute :rake, 'canvas:compile_assets --trace'
            execute :rake, 'canvas:compile_assets'
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
      set(:latest_release_path, releases_path.join(fetch(:latest_release)))

      # store the previous and current git revisions
      set(:release_revision, capture(:cat,release_path.join('REVISION')).strip)
      set(:latest_release_revision, capture(:cat, fetch(:latest_release_path).join('REVISION')).strip)
    end
  end

  desc "Check if compile_assets should run based on if there were changes to certain files.  E.g. check_compile_assets['some/path']"
  task :check_compile_assets, [:path_to_check] => :set_compile_assets_vars do |t, args|
    on roles(:all) do
      within repo_path do

        # Canvas compiles assets to the same directory and the source files that are in github.
        # So we can't just look at the local filesystem to compare if files changes, because that 
        # just ends up telling us that assets haven't been compiled no matter what.  So, instead 
        # we need to use git to tell if there is a change to the assets.
        #
        # This code reads the REVISION file from the previous release and compares the files in the specified
        # directory to this revision to see if there were any changes (specified in the asset_dependecies directories)
        #
        #changed_files = capture(:git,'diff --name-only', "#{fetch(:latest_release_revision)}", "HEAD~10", '--', "#{args[:path_to_check]}") # for testing
        changed_files = capture(:git,'diff --name-only', "#{fetch(:latest_release_revision)}", "#{fetch(:release_revision)}", '--', "#{args[:path_to_check]}")
        if !changed_files.empty? then raise PrecompileRequired
        end
      end
    end
  end

  # TODO: delete me
  desc "test task"
  task :test do
    on roles(:all) do
    #invoke("deploy:test1")
    #execute(:echo, "testvar1=",fetch(:test_var1))
    #invoke("deploy:set_compile_assets_vars")
    #execute(:echo, "latest_release=#{fetch(:latest_release)}")
    #execute(:echo, "latest_release_path=#{fetch(:latest_release_path)}")
    #execute(:echo, "release_revision=#{fetch(:release_revision)}")
    #execute(:echo, "latest_release_revision=#{fetch(:latest_release_revision)}")
    invoke("deploy:check_compile_assets", "app/views/shared")
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
