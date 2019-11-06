# Inspiration here: https://github.com/codetriage/codetriage/blob/master/config/puma.rb
# as referenced by: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#sample-code

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
# Note: after testing, if we notice that Canvas is not thread safe make it behave 
# like Phusion Passenger by only using 1 thread with multiple worker processes
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# Note: we need to tune this. It really depends on the memory available on the server.
# Since we use preload_app, the child workers share memory with the parent process
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

before_fork do
  # See: https://devcenter.heroku.com/articles/concurrency-and-database-connections#multi-process-servers
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

# Does a rolling restart of the worker processes to keep memory low. This gem is more of a bandaid than anything
# else. It basically makes sure memory leaks don't cause the process to get bloated, but if there are memory leaks
# we should fix the root cause.
# NOTE: commented out for now. Want to see if we have issues with memory usage creeping up before we enable.
#  require 'puma_worker_killer'
#  PumaWorkerKiller.enable_rolling_restart # Default is every 6 hours
end

on_worker_boot do
  # Configure the database pool on a per-process basis after it's forked b/c we're on Rails 4.0 and not Rails 4.1+
  # For details see: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  #   and
  # config/initializers/database_connection.rb for details.
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
    config['pool'] = ENV['DB_POOL'] || ENV['RAILS_MAX_THREADS'] || 5
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 15 # seconds
    ActiveRecord::Base.establish_connection(config)
  end
end
