namespace :heroku do
  namespace :reviewapps do

    # See: https://devcenter.heroku.com/articles/github-integration-review-apps
    desc "When a new Review App is created on Heroku, set it up."
    task :postdeploy do

      puts "### Running postdeploy rake task for the newly created Heroku Review App: #{ENV['HEROKU_APP_NAME']}"
     
      begin
        # See:
        # https://stackoverflow.com/questions/33293169/heroku-review-apps-copy-db-to-review-app
        # https://medium.com/uplaunch/software-deployment-pipeline-w-heroku-3f45e2d5445e
        puts "  Setting up Review App database: #{ENV['DATABASE_URL']} using the STAGING_DATABASE_URL from the parent app: #{ENV['DATABASE_URL']}"
        cmd = "pg_dump --no-owner -Fc #{ENV['STAGING_DATABASE_URL']} | pg_restore --clean --no-owner --no-acl -n public -d #{ENV['DATABASE_URL']}"
        puts cmd
        exec cmd

        # The Review App may be for a pull request with db migrations,
        # so we always run those. 
        puts "  Running db:migrate in case there are migrations in this pull request"
        Rake::Task['db:migrate'].invoke

      rescue => e
        puts "### Error: ignoring it so the Review App can deploy." 
        puts "--> DEBUG: #{e.message}"
        puts "--> DEBUG: #{e.backtrace.join("\n")}"
      end

    end
  
  end # Namespace: reviewapps
end # Namespace: heroku
