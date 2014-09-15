module Delayed

class TimeoutError < RuntimeError; end

require 'tmpdir'

class Worker

  Settings = [ :max_attempts ]
  cattr_accessor :queue, *Settings

  self.max_attempts = 15

  def self.queue=(queue_name)
    raise(ArgumentError, "queue_name must not be blank") if queue_name.blank?
    @@queue = queue_name
  end

  self.queue = "canvas_queue"

  attr_reader :config, :queue, :min_priority, :max_priority, :sleep_delay, :sleep_delay_stagger

  # Callback to fire when a delayed job fails max_attempts times. If this
  # callback is defined, then the value of destroy_failed_jobs is ignored, and
  # the job is destroyed if this block returns true.
  #
  # This allows for destroying "uninteresting" failures, while keeping around
  # interesting failures to be investigated later.
  #
  # The block is called with args(job, last_exception)
  def self.on_max_failures=(block)
    @@on_max_failures = block
  end
  cattr_reader :on_max_failures

  def self.lifecycle
    @lifecycle ||= Delayed::Lifecycle.new
  end

  def initialize(options = {})
    @exit = false
    @config = options
    @parent_pid = options[:parent_pid]
    @queue = options[:queue] || self.class.queue
    @min_priority = options[:min_priority]
    @max_priority = options[:max_priority]
    @max_job_count = options[:worker_max_job_count].to_i
    @max_memory_usage = options[:worker_max_memory_usage].to_i
    @job_count = 0

    app = Rails.application
    unless app.config.cache_classes
      Delayed::Worker.lifecycle.around(:perform) do |&block|
        reload = app.config.reload_classes_only_on_change != true || app.reloaders.map(&:updated?).any?
        ActionDispatch::Reloader.prepare! if reload
        begin
          block.call
        ensure
          ActionDispatch::Reloader.cleanup! if reload
        end
      end
    end
  end

  def name=(name)
    @name = name
  end

  def name
    @name ||= "#{Socket.gethostname rescue "X"}:#{self.id}"
  end

  def set_process_name(new_name)
    $0 = "delayed:#{new_name}"
  end

  def exit?
    @exit || parent_exited?
  end

  def parent_exited?
    @parent_pid && @parent_pid != Process.ppid
  end

  def start
    say "Starting worker", :info

    trap('INT') { say 'Exiting'; @exit = true }

    loop do
      run
      break if exit?
    end

    say "Stopping worker", :info
  rescue => e
    Rails.logger.fatal("Child process died: #{e.inspect}") rescue nil
    ErrorReport.log_exception(:delayed_jobs, e) rescue nil
  ensure
    Delayed::Job.clear_locks!(name)
  end

  def run
    # need to do this here, since we're avoiding db calls in the master process pre-fork
    @sleep_delay ||= Setting.get('delayed_jobs_sleep_delay', '5.0').to_f
    @sleep_delay_stagger ||= Setting.get('delayed_jobs_sleep_delay_stagger', '2.5').to_f
    @make_tmpdir ||= Setting.get('delayed_jobs_unique_tmpdir', 'true') == 'true'

    job =
        self.class.lifecycle.run_callbacks(:pop, self) do
          Delayed::Job.get_and_lock_next_available(
            name,
            queue,
            min_priority,
            max_priority)
        end

    if job
      configure_for_job(job) do
        @job_count += perform(job)

        if @max_job_count > 0 && @job_count >= @max_job_count
          say "Max job count of #{@max_job_count} exceeded, dying"
          @exit = true
        end

        if @max_memory_usage > 0
          memory = Canvas.sample_memory
          if memory > @max_memory_usage
            say "Memory usage of #{memory} exceeds max of #{@max_memory_usage}, dying"
            @exit = true
          else
            say "Memory usage: #{memory}"
          end
        end
      end
    else
      set_process_name("wait:#{Shard.current(:delayed_jobs).id}~#{@queue}:#{min_priority || 0}:#{max_priority || 'max'}")
      sleep(sleep_delay + (rand * sleep_delay_stagger))
    end
  end

  def perform(job)
    count = 1
    self.class.lifecycle.run_callbacks(:perform, self, job) do
      set_process_name("run:#{Shard.current(:delayed_jobs).id}~#{job.id}:#{job.name}")
      say("Processing #{log_job(job, :long)}", :info)
      runtime = Benchmark.realtime do
        if job.batch?
          # each job in the batch will have perform called on it, so we don't
          # need a timeout around this 
          count = perform_batch(job)
        else
          job.invoke_job
        end
        Delayed::Stats.job_complete(job, self)
        Rails.logger.quietly do
          job.destroy
        end
      end
      say("Completed #{log_job(job)} #{"%.0fms" % (runtime * 1000)}", :info)
    end
    count
  rescue Exception => e
    handle_failed_job(job, e)
    count
  end

  def perform_batch(parent_job)
    batch = parent_job.payload_object
    if batch.mode == :serial
      batch.jobs.each do |job|
        job.source = parent_job.source
        job.create_and_lock!(name)
        configure_for_job(job) do
          perform(job)
        end
      end
      batch.items.size
    end
  end

  def handle_failed_job(job, error)
    job.last_error = "#{error.message}\n#{error.backtrace.join("\n")}"
    say("Failed with #{error.class} [#{error.message}] (#{job.attempts} attempts)", :error)
    job.reschedule(error)
  end

  def id
    Process.pid
  end

  def say(msg, level = :debug)
    Rails.logger.send(level, msg)
  end

  def log_job(job, format = :short)
    case format
    when :long
      "#{job.full_name} #{ job.to_json(:include_root => false, :only => %w(tag strand priority attempts created_at max_attempts source)) }"
    else
      job.full_name
    end
  end

  # set up the session context information, so that it gets logged with the job log lines
  # also set up a unique tmpdir, which will get removed at the end of the job.
  def configure_for_job(job)
    previous_tmpdir = ENV['TMPDIR'] if @make_tmpdir
    Thread.current[:context] = {
      # these 2 keys aren't terribly well named for this, since they were intended for http requests
      :request_id => job.id,
      :session_id => self.name,
      :job        => job,
    }

    if @make_tmpdir
      Dir.mktmpdir("job-#{job.id}-#{self.name.gsub(/[^\w\.]/, '.')}-") do |dir|
        ENV['TMPDIR'] = dir
        yield
      end
    else
      yield
    end
  ensure
    ENV['TMPDIR'] = previous_tmpdir if @make_tmpdir
    Thread.current[:context] = nil
  end

  def self.current_job
    Thread.current[:context].try(:[], :job)
  end

end
end
