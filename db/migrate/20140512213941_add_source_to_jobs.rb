class AddSourceToJobs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Job.connection
  end

  def self.up
    add_column :delayed_jobs, :source, :string
    add_column :failed_jobs, :source, :string
  end

  def self.down
    remove_column :delayed_jobs, :source
    remove_column :failed_jobs, :source
  end
end
