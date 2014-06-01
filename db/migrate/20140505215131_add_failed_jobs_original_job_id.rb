class AddFailedJobsOriginalJobId < ActiveRecord::Migration
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_column :failed_jobs, :original_job_id, :integer, limit: 8
  end

  def self.down
    remove_column :failed_jobs, :original_job_id
  end
end
