class IndexJobsOnLockedBy < ActiveRecord::Migration
  tag :predeploy

  self.transactional = false

  def self.connection
    Delayed::Job.connection
  end

  def self.up
    case connection.adapter_name
    when 'PostgreSQL'
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_delayed_jobs_on_locked_by ON delayed_jobs (locked_by) WHERE locked_by IS NOT NULL;
      SQL
    else
      add_index :delayed_jobs, :locked_by, :name => "index_delayed_jobs_on_locked_by"
    end
  end

  def self.down
    remove_index :delayed_jobs, :name => "index_delayed_jobs_on_locked_by"
  end
end
