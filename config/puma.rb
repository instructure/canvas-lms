# Inspiration here: https://github.com/codetriage/codetriage/blob/master/config/puma.rb
# as referenced by: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#sample-code

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
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
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart

# Does a rolling restart of the worker processes to keep memory low. This gem is more of a bandaid than anything
# else. It basically makes sure memory leaks don't cause the process to get bloated, but if there are memory leaks
# we should fix the root cause.
# NOTE: commented out for now. Want to see if we have issues with memory usage creeping up before we enable.
#before_fork do
#  require 'puma_worker_killer'
#
#  PumaWorkerKiller.enable_rolling_restart # Default is every 6 hours
#end

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
