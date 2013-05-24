class AddJobsRunAtIndex < ActiveRecord::Migration
  tag :predeploy

  self.transactional = false

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_index :delayed_jobs, %w[run_at tag], :concurrently => true
  end

  def self.down
    remove_index :delayed_jobs, :name => "index_delayed_jobs_on_run_at_and_tag"
  end
end
