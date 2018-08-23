#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

Delayed::Job.include(JobLiveEventsContext)

Delayed::Backend::Base.class_eval do
  attr_writer :current_shard

  def current_shard
    @current_shard || Shard.birth
  end
end

# if the method was defined by a previous module, use the existing
# implementation, but provide a default otherwise
module Delayed::Backend::DefaultJobAccount
  def account
    if defined?(super)
      super
    else
      Account.default
    end
  end
end
Delayed::Backend::ActiveRecord::Job.include(Delayed::Backend::DefaultJobAccount)
Delayed::Backend::Redis::Job.include(Delayed::Backend::DefaultJobAccount)

Delayed::Settings.max_attempts              = 1
Delayed::Settings.queue                     = "canvas_queue"
Delayed::Settings.sleep_delay               = ->{ Setting.get('delayed_jobs_sleep_delay', '2.0').to_f }
Delayed::Settings.sleep_delay_stagger       = ->{ Setting.get('delayed_jobs_sleep_delay_stagger', '2.0').to_f }
Delayed::Settings.fetch_batch_size          = ->{ Setting.get('jobs_get_next_batch_size', '5').to_i }
Delayed::Settings.select_random_from_batch  = ->{ Setting.get('jobs_select_random', 'false') == 'true' }
Delayed::Settings.num_strands               = ->(strand_name){ Setting.get("#{strand_name}_num_strands", nil) }
Delayed::Settings.worker_procname_prefix    = ->{ "#{Shard.current(:delayed_jobs).id}~" }
Delayed::Settings.pool_procname_suffix      = " (#{Canvas.revision})" if Canvas.revision
Delayed::Settings.worker_health_check_type  = Delayed::CLI.instance&.config&.dig('health_check', 'type')&.to_sym || :none
Delayed::Settings.worker_health_check_config = Delayed::CLI.instance&.config&.[]('health_check')

Delayed::Settings.default_job_options = ->{
  {
    current_shard: Shard.current,
  }
}

# load our periodic_jobs.yml (cron overrides config file)
Delayed::Periodic.add_overrides(ConfigFile.load('periodic_jobs') || {})

if ActiveRecord::Base.configurations[Rails.env]['queue']
  ActiveSupport::Deprecation.warn("A queue section in database.yml is no longer supported. Please run migrations, then remove it.")
end

# configure autoscaling plugin
if (config = Delayed::CLI.instance&.config&.[](:auto_scaling))
  require 'jobs_autoscaling'
  actions = [JobsAutoscaling::LoggerAction.new]
  if config[:asg_name]
    aws_config = config[:aws_config] || {}
    aws_config[:region] ||= ApplicationController.region
    actions << JobsAutoscaling::AwsAction.new(asg_name: config[:asg_name],
                                            aws_config: aws_config,
                                            instance_id: ApplicationController.instance_id)
  end
  autoscaler = JobsAutoscaling::Monitor.new(action: actions)
  autoscaler.activate!
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
  Canvas::Reloader.reload! if Canvas::Reloader.pending_reload

  # context for our custom logger
  Thread.current[:context] = {
    # these 2 keys aren't terribly well named for this, since they were intended for http requests
    :request_id => job.id,
    :session_id => worker.name,
  }

  LiveEvents.set_context(job.live_events_context)

  HostUrl.reset_cache!
  old_root_account = Attachment.current_root_account
  Attachment.current_root_account = job.account

  starting_mem = Canvas.sample_memory()
  starting_cpu = Process.times()
  lag = ((Time.now - job.run_at) * 1000).round
  obj_tag, method_tag = job.tag.split(/[\.#]/, 2).map do |v|
    CanvasStatsd::Statsd.escape(v).gsub("::", "-")
  end
  method_tag ||= "unknown"
  shard_id = job.current_shard.try(:id).to_i
  stats = ["delayedjob.queue", "delayedjob.queue.tag.#{obj_tag}.#{method_tag}", "delayedjob.queue.shard.#{shard_id}"]
  stats << "delayedjob.queue.jobshard.#{job.shard.id}" if job.respond_to?(:shard)
  CanvasStatsd::Statsd.timing(stats, lag)

  begin
    stats = ["delayedjob.perform", "delayedjob.perform.tag.#{obj_tag}.#{method_tag}", "delayedjob.perform.shard.#{shard_id}"]
    stats << "delayedjob.perform.jobshard.#{job.shard.id}" if job.respond_to?(:shard)
    CanvasStatsd::Statsd.time(stats) do
      block.call(worker, job)
    end
  ensure
    ending_cpu = Process.times()
    ending_mem = Canvas.sample_memory()
    user_cpu = ending_cpu.utime - starting_cpu.utime
    system_cpu = ending_cpu.stime - starting_cpu.stime

    Attachment.current_root_account = old_root_account

    LiveEvents.clear_context!

    Rails.logger.info "[STAT] #{starting_mem} #{ending_mem} #{ending_mem - starting_mem} #{user_cpu} #{system_cpu}"

    Thread.current[:context] = nil
  end
end

Delayed::Worker.lifecycle.around(:pop) do |worker, &block|
  CanvasStatsd::Statsd.time(["delayedjob.pop", "delayedjob.pop.jobshard.#{Shard.current(:delayed_jobs).id}"]) do
    block.call(worker)
  end
end

Delayed::Worker.lifecycle.around(:work_queue_pop) do |worker, config, &block|
  CanvasStatsd::Statsd.time(["delayedjob.workqueuepop", "delayedjob.workqueuepop.jobshard.#{Shard.current(:delayed_jobs).id}"]) do
    block.call(worker, config)
  end
end

Delayed::Worker.lifecycle.before(:perform) do |_worker, _job|
  # Since AdheresToPolicy::Cache uses an instance variable class cache lets clear
  # it so we start with a clean slate.
  AdheresToPolicy::Cache.clear
  LoadAccount.clear_shard_cache
end

Delayed::Worker.lifecycle.around(:perform) do |worker, job, &block|
  CanvasStatsd::Statsd.batch do
    block.call(worker, job)
  end
end

Delayed::Worker.lifecycle.before(:exceptional_exit) do |worker, exception|
  info = Canvas::Errors::WorkerInfo.new(worker)
  Canvas::Errors.capture(exception, info.to_h)
end

Delayed::Worker.lifecycle.before(:error) do |worker, job, exception|
  info = Canvas::Errors::JobInfo.new(job, worker)
  begin
    (job.current_shard || Shard.default).activate do
      Canvas::Errors.capture(exception, info.to_h)
    end
  rescue
    Canvas::Errors.capture(exception, info.to_h)
  end
end
