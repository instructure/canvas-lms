class IndexJobsOnLockedBy < ActiveRecord::Migration
  tag :predeploy

  disable_ddl_transaction!

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_index :delayed_jobs, :locked_by, :algorithm => :concurrently, :where => "locked_by IS NOT NULL"
  end

  def self.down
    remove_index :delayed_jobs, :locked_by
  end
end
