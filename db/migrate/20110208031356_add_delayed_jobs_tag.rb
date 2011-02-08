class AddDelayedJobsTag < ActiveRecord::Migration
  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_column :delayed_jobs, :tag, :string
    add_index :delayed_jobs, [:tag]
  end

  def self.down
    remove_column :delayed_jobs, :tag
  end
end
