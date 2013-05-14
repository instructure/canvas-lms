class IndexJobsOnLockedBy < ActiveRecord::Migration
  tag :predeploy

  self.transactional = false

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_index :delayed_jobs, :locked_by, :concurrently => true, :conditions => "locked_by IS NOT NULL"
  end

  def self.down
    remove_index :delayed_jobs, :locked_by
  end
end
