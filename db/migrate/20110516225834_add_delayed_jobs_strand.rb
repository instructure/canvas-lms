class AddDelayedJobsStrand < ActiveRecord::Migration
  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    add_column :delayed_jobs, :strand, :string
    add_index :delayed_jobs, :strand
  end

  def self.down
    remove_column :delayed_jobs, :strand
  end
end
