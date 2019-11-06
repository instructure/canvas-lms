# Taken from: https://devcenter.heroku.com/articles/concurrency-and-database-connections
# Use config/database.yml method if you are using Rails 4.1+
Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.disconnect!

  ActiveSupport.on_load(:active_record) do
    # Set the maximum number of the connections the process can have to the database
    # Note: this is duplicated in the web-server after fork b/c the pool is per process.
    # E.g. config/puma.rb::on_worker_boot()
    # Also, be careful to calculate the number of total connections the app will
    # make with these settings so they don't exceed the database connection limit.
    config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
    config['pool'] = ENV['DB_POOL'] || ENV['RAILS_MAX_THREADS'] || 5
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 15 # seconds
    ActiveRecord::Base.establish_connection(config)
  end
end
