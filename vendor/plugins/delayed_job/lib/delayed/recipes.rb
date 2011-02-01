# Capistrano Recipes for managing delayed_job
#
# Add these callbacks to have the delayed_job process restart when the server
# is restarted:
#
#   after "deploy:stop",    "delayed_job:stop"
#   after "deploy:start",   "delayed_job:start"
#   after "deploy:restart", "delayed_job:restart"

Capistrano::Configuration.instance.load do
  namespace :delayed_job do
    def rails_env
      fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
    end
    
    desc "Stop the delayed_job process"
    task :stop, :roles => :app do
      run "cd #{current_path};#{rails_env} script/delayed_job stop"
    end

    desc "Start the delayed_job process"
    task :start, :roles => :app do
      run "cd #{current_path};#{rails_env} script/delayed_job start"
    end

    desc "Restart the delayed_job process"
    task :restart, :roles => :app do
      run "cd #{current_path};#{rails_env} script/delayed_job restart"
    end
  end
end