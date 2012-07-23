class AddJobsRunAtIndex < ActiveRecord::Migration
  tag :predeploy

  self.transactional = false

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    case connection.adapter_name
    when 'PostgreSQL'
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_delayed_jobs_on_run_at_and_tag ON delayed_jobs (run_at, tag);
      SQL
    else
      add_index :delayed_jobs, %w[run_at tag], :name => "index_delayed_jobs_on_run_at_and_tag"
    end
  end

  def self.down
    remove_index :delayed_jobs, :name => "index_delayed_jobs_on_run_at_and_tag"
  end
end
