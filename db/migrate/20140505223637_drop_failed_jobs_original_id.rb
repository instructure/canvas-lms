class DropFailedJobsOriginalId < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    remove_column :failed_jobs, :original_id
  end

  def self.down
    add_column :failed_jobs, :original_id, :integer, limit: 8
  end
end
