# See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#thread-safety
# Tried running Puma with 4 workers and 1 thread to concurrency, but under
# heavy load the request queue got too long and things started hanging as
# connections timed out. It put puma in a bad state. Going to try configuring less workers
# (like 2-3) and enable threads, but keep everything single threaded using Rack:Lock.
if ENV['RACK_LOCK']
  Rails.application.config.middleware.insert_before 0, Rack::Lock
end
