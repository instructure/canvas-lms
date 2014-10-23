require 'rufus-scheduler'

module Delayed
class Periodic
  attr_reader :name, :cron

  yaml_as "tag:ruby.yaml.org,2002:Delayed::Periodic"

  def to_yaml(opts = {})
    YAML.quick_emit(self.object_id, opts) { |out| out.scalar(taguri, @name) }
  end

  def self.yaml_new(klass, tag, val)
    self.scheduled[val] || raise(NameError, "job #{val} is no longer scheduled")
  end

  cattr_accessor :scheduled
  self.scheduled = {}

  # throws an error if any cron override in config/periodic_jobs.yml is invalid
  def self.audit_overrides!
    overrides = ConfigFile.load('periodic_jobs') || {}
    overrides.each do |name, cron_line|
      # throws error if the line is malformed
      Rufus::CronLine.new(cron_line)
    end
  end

  def self.load_periodic_jobs_config
    require Rails.root+'config/periodic_jobs'
  end

  STRAND = 'periodic scheduling'

  def self.cron(job_name, cron_line, job_args = {}, &block)
    raise ArgumentError, "job #{job_name} already scheduled!" if self.scheduled[job_name]
    override = (ConfigFile.load('periodic_jobs') || {})[job_name]
    cron_line = override if override
    self.scheduled[job_name] = self.new(job_name, cron_line, job_args, block)
  end

  def self.audit_queue
    # we used to queue up a job in a strand here, and perform the audit inside that job
    # however, now that we're using singletons for scheduling periodic jobs,
    # it's fine to just do the audit in-line here without risk of creating duplicates
    perform_audit!
  end

  # make sure all periodic jobs are scheduled for their next run in the job queue
  # this auditing should run on the strand
  def self.perform_audit!
    self.scheduled.each { |name, periodic| periodic.enqueue }
  end

  def initialize(name, cron_line, job_args, block)
    @name = name
    @cron = Rufus::CronLine.new(cron_line)
    @job_args = { :priority => Delayed::LOW_PRIORITY }.merge(job_args.symbolize_keys)
    @block = block
  end

  def enqueue
    Delayed::Job.enqueue(self, @job_args.merge(:max_attempts => 1, :run_at => @cron.next_time(Delayed::Periodic.now), :singleton => tag))
  end

  def perform
    @block.call()
  ensure
    begin
      enqueue
    rescue
      # double fail! the auditor will have to catch this.
      Rails.logger.error "Failure enqueueing periodic job! #{@name} #{$!.inspect}"
    end
  end

  def tag
    "periodic: #{@name}"
  end
  alias_method :display_name, :tag

  def self.now
    Time.now
  end
end
end
