Delayed::Backend::Base.class_eval do
  attr_writer :current_shard

  def current_shard
    @current_shard || Shard.birth
  end
end

Delayed::Settings.max_attempts              = 15
Delayed::Settings.queue                     = "canvas_queue"
Delayed::Settings.sleep_delay               = ->{ Setting.get('delayed_jobs_sleep_delay', '2.0').to_f }
Delayed::Settings.sleep_delay_stagger       = ->{ Setting.get('delayed_jobs_sleep_delay_stagger', '2.0').to_f }
Delayed::Settings.fetch_batch_size          = ->{ Setting.get('jobs_get_next_batch_size', '5').to_i }
Delayed::Settings.select_random_from_batch  = ->{ Setting.get('jobs_select_random', 'false') == 'true' }
Delayed::Settings.num_strands               = ->(strand_name){ Setting.get("#{strand_name}_num_strands", nil) }
Delayed::Settings.worker_procname_prefix    = ->{ "#{Shard.current(:delayed_jobs).id}~" }
Delayed::Settings.pool_procname_suffix      = " (#{Canvas.revision})" if Canvas.revision

Delayed::Settings.default_job_options = ->{
  {
    current_shard: Shard.current,
  }
}

# load our periodic_jobs.yml (cron overrides config file)
Delayed::Periodic.add_overrides(ConfigFile.load('periodic_jobs') || {})

# If there is a sub-hash under the 'queue' key for the database config, use that
# as the connection for the job queue. The migration that creates the
# delayed_jobs table is smart enough to use this connection as well.
db_queue_config = ActiveRecord::Base.configurations[Rails.env]['queue']
if db_queue_config
  Delayed::Backend::ActiveRecord::Job.establish_connection(db_queue_config)
end

Delayed::Worker.on_max_failures = proc do |job, err|
  # We don't want to keep around max_attempts failed jobs that failed because the
  # underlying AR object was destroyed.
  # All other failures are kept for inspection.
  err.is_a?(Delayed::Backend::RecordNotFound)
end

### lifecycle callbacks

Delayed::Pool.on_fork = ->{
  Canvas.reconnect_redis
}

Delayed::Worker.lifecycle.around(:perform) do |worker, job, &block|
  # context for our custom logger
  Thread.current[:context] = {
    # these 2 keys aren't terribly well named for this, since they were intended for http requests
    :request_id => job.id,
    :session_id => worker.name,
  }

  starting_mem = Canvas.sample_memory()
  starting_cpu = Process.times()
  lag = ((Time.now - job.run_at) * 1000).round
  tag = CanvasStatsd::Statsd.escape(job.tag)
  shard_id = job.current_shard.try(:id).to_i
  stats = ["delayedjob.queue", "delayedjob.queue.tag.#{tag}", "delayedjob.queue.shard.#{shard_id}"]
  stats << "delayedjob.queue.jobshard.#{job.shard.id}" if job.respond_to?(:shard)
  CanvasStatsd::Statsd.timing(stats, lag)
  begin
    stats = ["delayedjob.perform", "delayedjob.perform.tag.#{tag}", "delayedjob.perform.shard.#{shard_id}"]
    stats << "delayedjob.perform.jobshard.#{job.shard.id}" if job.respond_to?(:shard)
    CanvasStatsd::Statsd.time(stats) do
      block.call(worker, job)
    end
  ensure
    ending_cpu = Process.times()
    ending_mem = Canvas.sample_memory()
    user_cpu = ending_cpu.utime - starting_cpu.utime
    system_cpu = ending_cpu.stime - starting_cpu.stime
    Thread.current[:context] = nil

    Rails.logger.info "[STAT] #{starting_mem} #{ending_mem} #{ending_mem - starting_mem} #{user_cpu} #{system_cpu}"
  end
end

Delayed::Worker.lifecycle.around(:pop) do |worker, &block|
  CanvasStatsd::Statsd.time(["delayedjob.pop", "delayedjob.pop.jobshard.#{Shard.current(:delayed_jobs).id}"]) do
    block.call(worker)
  end
end

Delayed::Worker.lifecycle.before(:perform) do |job|
  # Since AdheresToPolicy::Cache uses an instance variable class cache lets clear
  # it so we start with a clean slate.
  AdheresToPolicy::Cache.clear
  LoadAccount.clear_shard_cache
end

Delayed::Worker.lifecycle.before(:exceptional_exit) do |worker, exception|
  ErrorReport.log_exception(:delayed_jobs, exception) rescue nil
end
