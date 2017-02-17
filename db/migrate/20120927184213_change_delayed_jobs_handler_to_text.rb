class ChangeDelayedJobsHandlerToText < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Job.connection
  end

  def self.up
    change_column :delayed_jobs, :handler, :text
  end

  def self.down
    change_column :delayed_jobs, :handler, :string, :limit => 500.kilobytes
  end
end
