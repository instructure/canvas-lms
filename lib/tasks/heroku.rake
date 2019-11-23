namespace :heroku do
  namespace :app do
    require 'platform-api'
    
      # Example call: HEROKU_OAUTH_TOKEN=my-token HEROKU_APP_NAME=my-app bundle exec rake heroku:app:restart_dyno[web]
      desc "Restart a dyno."
      task :restart_dyno, [:dyno_name] => :environment do |t, args|

        # Note: get the HEROKU_OAUTH_TOKEN using:
        #   heroku authorizations:create -d "Portal Admin API token" 
        heroku = PlatformAPI.connect_oauth(ENV['HEROKU_OAUTH_TOKEN'])

        # Note: HEROKU_APP_NAME is supposed to be availble on a normal dyno (in addition to Review Apps) after running:
        #   heroku labs:enable runtime-dyno-metadata
        # but it didn't seem to be so I set it manually
        heroku.dyno.restart(ENV['HEROKU_APP_NAME'], args[:dyno_name])

      end

  end # Namespace: app

  namespace :reviewapps do

    # See: https://devcenter.heroku.com/articles/github-integration-review-apps
    desc "When a new Review App is created on Heroku, set it up."
    task :postdeploy do

      # If you change this, the most important thing to keep in mind is that we want to prevent blowing
      # away a production database. Make sure and keep checks in place that prevent that!
      raise RuntimeError.new("This task can only be run for a Heroku Review App (indicated by the existence of ENV['HEROKU_APP_NAME'])") unless ENV['HEROKU_APP_NAME']
      raise RuntimeError.new("The ENV['STAGING_DATABASE_URL'] must be set in order to create a Heroku Review App.") unless ENV['STAGING_DATABASE_URL']

      begin
        puts "### Running postdeploy rake task for the newly created Heroku Review App: #{ENV['HEROKU_APP_NAME']}\n"

        # See:
        # https://stackoverflow.com/questions/33293169/heroku-review-apps-copy-db-to-review-app
        # https://medium.com/uplaunch/software-deployment-pipeline-w-heroku-3f45e2d5445e
        puts "Setting up Review App database ENV['STAGING_DATABASE_URL'] from the parent app"
        cmd = "pg_dump --no-owner --no-acl -Fc #{ENV['STAGING_DATABASE_URL']} | pg_restore --no-owner --no-acl -n public -d #{ENV['DATABASE_URL']} 2>&1"
        db_restore_result = `#{cmd}`
        puts "#{db_restore_result}"

        # The Review App may be for a pull request with db migrations,
        # so we always run those. 
        puts "Running db:migrate in case there are migrations in this pull request"
        Rake::Task['db:migrate'].invoke

      rescue => e
        puts "### Error: ignoring it so the Review App can deploy. Prob want to fix tho." 
        puts "--> DEBUG: #{e.message}"
        puts "--> DEBUG: #{e.backtrace.join("\n")}"
      end

    end
  
  end # Namespace: reviewapps
end # Namespace: heroku
