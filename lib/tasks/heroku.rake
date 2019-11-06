namespace :heroku do
  namespace :reviewapps do

    # See: https://devcenter.heroku.com/articles/github-integration-review-apps
    desc "When a new Review App is created on Heroku, set it up."
    task :postdeploy do

      puts "### Running postdeploy rake task for the newly created Heroku Review App: #{ENV['HEROKU_APP_NAME']}"

      # TODO: create and populate a real database." 
      Rake::Task['db:create'].invoke

      # Note: we still run migrations on the database once we cutover to load
      # one with real data in case they were in the code used to create the 
      # app and need to be applied.
      Rake::Task['db:migrate'].invoke

      # TODO: create and populate a real database." 
      Rake::Task['db:initial_setup'].invoke
    end
  
  end # Namespace: reviewapps
end # Namespace: heroku
