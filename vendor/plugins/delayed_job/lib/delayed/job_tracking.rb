module Delayed
# Used when a block of code wants to track what jobs are created,
# for instance in tests.
# Delayed::Job.track_jobs { ...block... } returns a JobTracking object
# Right now this just tracks created jobs, it could be expanded to track a
# lot more about what's going on in Delayed Jobs as it's needed.
class JobTracking < Struct.new(:created)
  def self.track
    @current_tracking = self.new
    yield
    tracking = @current_tracking
    @current_tracking = nil
    tracking
  end

  def self.job_created(job)
    @current_tracking.try(:job_created, job)
  end

  def job_created(job)
    return unless job
    @lock.synchronize { self.created << job }
  end

  def initialize
    super
    self.created = []
    @lock = Mutex.new
  end
end
end
