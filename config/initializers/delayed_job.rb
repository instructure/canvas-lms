# If there is a sub-hash under the 'queue' key for the database config, use that
# as the connection for the job queue. The migration that creates the
# delayed_jobs table is smart enough to use this connection as well.
queue_config = ActiveRecord::Base.configurations[Rails.env]['queue']
if queue_config
  Delayed::Backend::ActiveRecord::Job.establish_connection(queue_config)
end

# We don't want to keep around max_attempts failed jobs that failed because the
# underlying AR object was destroyed.
Delayed::Worker.on_max_failures = proc do |job, err|
  if err.is_a?(Delayed::Backend::RecordNotFound)
    return true
  end

  # by default, keep failed jobs around for investigation
  false
end
