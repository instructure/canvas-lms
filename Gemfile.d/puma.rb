group :puma do
  # This is the last version to support Ruby 2.1
  gem 'puma', '3.11.4'
  # If we run into memory leaks, maybe use this to enable rolling restarts of worker processes.
  #gem 'puma_worker_killer'
end
