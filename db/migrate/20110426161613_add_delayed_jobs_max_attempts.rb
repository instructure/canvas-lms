class AddDelayedJobsMaxAttempts < ActiveRecord::Migration
  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_column :delayed_jobs, :max_attempts, :integer
  end

  def self.down
    remove_column :delayed_jobs, :max_attempts
  end
end
