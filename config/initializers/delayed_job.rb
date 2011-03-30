Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts = 15
Delayed::Worker.queue = "canvas_queue"

module Delayed
  HIGH_PRIORITY = 0
  NORMAL_PRIORITY = 10
  LOW_PRIORITY = 20
end

Delayed::Job.default_priority = Delayed::NORMAL_PRIORITY

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
  if err.is_a?(Delayed::PerformableMethod::LoadError)
    return true
  end

  # by default, keep failed jobs around for investigation
  false
end

class Object
  def send_later_if_production(*args)
    if Rails.env.production?
      send_later(*args)
    else
      send(*args)
    end
  end

  def send_later_if_production_enqueue_args(method, enqueue_args, *args)
    if Rails.env.production?
      send_later_enqueue_args(method, enqueue_args, *args)
    else
      send(method, *args)
    end
  end
end
