module Delayed

class TimeoutError < RuntimeError; end

class Worker

  Settings = [ :max_run_time, :max_attempts ]
  cattr_accessor :queue, *Settings

  self.max_attempts = 15
  self.max_run_time = 4.hours
  self.queue = "canvas_queue"

  attr_reader :config, :queue, :min_priority, :max_priority, :sleep_delay

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

  def initialize(parent_pid, options = {})
    @parent_pid = parent_pid
    @config = options
    @exit = false
    @queue = options[:queue] || self.class.queue
    @min_priority = options[:min_priority]
    @max_priority = options[:max_priority]
    @sleep_delay = Setting.get('delayed_jobs_sleep_delay', '1.0').to_f
  end

  def name
    @name ||= "#{Socket.gethostname rescue "X"}:#{Process.pid}"
  end

  def exit?
    @exit || parent_exited?
  end

  def parent_exited?
    @parent_pid != Process.ppid
  end

  def start
    say "Starting job worker", :info

    trap('INT') { say 'Exiting'; @exit = true }

    loop do
      run
      break if exit?
    end
  ensure
    Delayed::Job.clear_locks!(name)
  end

  protected

  def run
    job = nil
    Rails.logger.silence do
      job = Delayed::Job.get_and_lock_next_available(
        name,
        self.class.max_run_time,
        queue,
        min_priority,
        max_priority)
    end

    if job
      perform(job)
    else
      sleep(sleep_delay)
    end
  end

  def perform(job)
    start_time = Time.now
    say_job(job, "Processing #{log_job(job, :long)}", :info)
    runtime = Benchmark.realtime do
      Timeout.timeout(self.class.max_run_time.to_i, Delayed::TimeoutError) { job.invoke_job }
      Rails.logger.silence do
        job.destroy
      end
    end
    say_job(job, "Completed #{log_job(job)} %.0fms" % (runtime * 1000), :info)
  rescue Exception => e
    handle_failed_job(job, e)
  end

  def handle_failed_job(job, error)
    job.last_error = error.message + "\n" + error.backtrace.join("\n")
    say_job(job, "Failed with #{error.class} [#{error.message}] (#{job.attempts} attempts)", :error)
    reschedule(job, error)
  end

  # Reschedule the job in the future (when a job fails).
  # Uses an exponential scale depending on the number of failed attempts.
  def reschedule(job, error = nil, time = nil)
    job.attempts += 1
    if job.attempts >= (job.max_attempts || self.class.max_attempts)
      job.failed_at = Delayed::Job.db_time_now
      destroy_job = true
      if self.class.on_max_failures
        destroy_job = self.class.on_max_failures.call(job, error)
      end
      if destroy_job
        say "destroying #{job.name} because of #{job.attempts} consecutive failures.", :info
        job.destroy
      end
    end

    # still reschedule even if the job has failed max_attempts times -- maybe
    # somebody will increase max_attempts later
    time ||= job.reschedule_at
    job.run_at = time
    job.unlock
    job.save!
  end

  def say(msg, level = :debug)
    Rails.logger.send(level, "[#{Process.pid}]W #{msg}")
  end

  def say_job(job, msg, level = :debug)
    say("job_id:#{job.id} #{msg}", level)
  end

  def log_job(job, format = :short)
    case format
    when :long
      "#{job.full_name} #{ job.to_json(:include_root => false, :only => %w(priority attempts created_at max_attempts)) }"
    else
      job.full_name
    end
  end

end
end
