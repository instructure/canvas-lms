# frozen_string_literal: true

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
require_relative './job_live_events_context'
Delayed::Job.include(JobLiveEventsContext)

Delayed::Backend::Base.class_eval do
  attr_writer :current_shard

  def current_shard
    @current_shard || Shard.birth
  end

  def root_account_id
    return nil if account.nil?

    account.resolved_root_account_id
  end

  def to_log_format
    logged_attributes = [:tag, :strand, :priority, :attempts, :created_at, :max_attempts, :source, :account_id]
    log_hash = attributes.with_indifferent_access.slice(*logged_attributes)
    log_hash[:shard_id] = current_shard&.id
    log_hash[:jobs_cluster] = "NONE"
    if current_shard.respond_to?(:delayed_jobs_shard_id)
      log_hash[:jobs_cluster] = current_shard&.delayed_jobs_shard&.id
    end
    log_hash[:db_cluster] = current_shard&.database_server&.id
    log_hash[:root_account_id] = Shard.global_id_for(root_account_id)
    log_hash.with_indifferent_access.to_json
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

Delayed::Settings.default_job_options        = ->{ { current_shard: Shard.current }}
Delayed::Settings.fetch_batch_size           = ->{ Setting.get('jobs_get_next_batch_size', '5').to_i }
Delayed::Settings.job_detailed_log_format    = ->(job){ job.to_log_format }
Delayed::Settings.max_attempts               = 1
Delayed::Settings.num_strands                = ->(strand_name){ Setting.get("#{strand_name}_num_strands", nil) }
Delayed::Settings.pool_procname_suffix       = " (#{Canvas.revision})" if Canvas.revision
Delayed::Settings.queue                      = "canvas_queue"
Delayed::Settings.select_random_from_batch   = ->{ Setting.get('jobs_select_random', 'false') == 'true' }
Delayed::Settings.sleep_delay                = ->{ Setting.get('delayed_jobs_sleep_delay', '2.0').to_f }
Delayed::Settings.sleep_delay_stagger        = ->{ Setting.get('delayed_jobs_sleep_delay_stagger', '2.0').to_f }
Delayed::Settings.worker_procname_prefix     = ->{ "#{Shard.current(:delayed_jobs).id}~" }
Delayed::Settings.worker_health_check_type   = Delayed::CLI.instance&.config&.dig('health_check', 'type')&.to_sym || :none
Delayed::Settings.worker_health_check_config = Delayed::CLI.instance&.config&.[]('health_check')

# load our periodic_jobs.yml (cron overrides config file)
Delayed::Periodic.add_overrides(ConfigFile.load('periodic_jobs').dup || {})

if ActiveRecord::Base.configurations[Rails.env]['queue']
  ActiveSupport::Deprecation.warn("A queue section in database.yml is no longer supported. Please run migrations, then remove it.")
end


Rails.application.config.after_initialize do
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
end

Delayed::Worker.on_max_failures = proc do |job, err|
  # We don't want to keep around max_attempts failed jobs that failed because the
  # underlying AR object was destroyed.
  # All other failures are kept for inspection.
  err.is_a?(Delayed::Backend::RecordNotFound)
end

module DelayedJobConfig
  class << self
    def config
      @config ||= YAML.load(Canvas::DynamicSettings.find(tree: :private)['delayed_jobs.yml'] || '{}')
    end

    def strands_to_send_to_statsd
      @strands_to_send_to_statsd ||= (config['strands_to_send_to_statsd'] || []).to_set
    end

    def reload
      @config = @strands_to_send_to_statsd = nil
    end
    Canvas::Reloader.on_reload { DelayedJobConfig.reload }
  end
end

### lifecycle callbacks

Delayed::Worker.lifecycle.around(:perform) do |worker, job, &block|
  Canvas::Reloader.reload! if Canvas::Reloader.pending_reload
  Canvas::Redis.clear_idle_connections
  job.current_shard.activate do
    LoadAccount.check_schema_cache
  end

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

  begin
    RequestCache.enable do
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

Delayed::Worker.lifecycle.before(:perform) do |_worker, _job|
  # Since AdheresToPolicy::Cache uses an instance variable class cache lets clear
  # it so we start with a clean slate.
  AdheresToPolicy::Cache.clear
  LoadAccount.clear_shard_cache
end

Delayed::Worker.lifecycle.before(:exceptional_exit) do |worker, exception|
  info = Canvas::Errors::WorkerInfo.new(worker)
  Canvas::Errors.capture(exception, info.to_h)
end

Delayed::Worker.lifecycle.before(:retry) do |worker, job, exception|
  # any job that fails with a RetriableError gets routed
  # here if it has any retries left.  We just want the stats
  info = Canvas::Errors::JobInfo.new(job, worker)
  begin
    (job.current_shard || Shard.default).activate do
      Canvas::Errors.capture(exception, info.to_h, :info)
    end
  rescue => e
    Canvas::Errors.capture_exception(:jobs_lifecycle, e)
    Canvas::Errors.capture(exception, info.to_h, :info)
  end
end

# Delayed::Backend::RecordNotFound happens when a job is queued and then the thing that
# it's queued on gets deleted.  It happens all the time for stuff
# like test students (we delete their stuff immediately), and
# we don't need detailed exception reports for those.
#
# Delayed::RetriableError is thrown by any job to indicate the thing
# that's failing is "kind of expected".  Upstream service backpressure,
# etc.
WARNABLE_DELAYED_EXCEPTIONS = [
  Delayed::Backend::RecordNotFound,
  Delayed::RetriableError,
].freeze

Delayed::Worker.lifecycle.before(:error) do |worker, job, exception|
  is_warnable = WARNABLE_DELAYED_EXCEPTIONS.any?{|klass| exception.is_a?(klass) }
  error_level = is_warnable ? :warn : :error
  info = Canvas::Errors::JobInfo.new(job, worker)
  begin
    (job.current_shard || Shard.default).activate do
      Canvas::Errors.capture(exception, info.to_h, error_level)
    end
  rescue
    Canvas::Errors.capture(exception, info.to_h, error_level)
  end
end

# syntactic sugar and compatibility shims
module CanvasDelayedMessageSending
  def delay_if_production(sender: nil, **kwargs)
    sender ||= __calculate_sender_for_delay
    delay(sender: sender, **kwargs.merge(synchronous: !Rails.env.production?))
  end
end
Object.send(:include, CanvasDelayedMessageSending)
