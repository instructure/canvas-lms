class IndexDelayedJobsWithStrand < ActiveRecord::Migration
  def self.connection
    Delayed::Job.connection
  end

  def self.up
    remove_index :delayed_jobs, :strand
    remove_index :delayed_jobs, :name => 'get_delayed_jobs_index'

    case connection.adapter_name
    when 'PostgreSQL'
      # "nulls first" syntax is postgresql specific, and allows for more
      # efficient querying for the next job
      connection.execute("CREATE INDEX get_delayed_jobs_index ON delayed_jobs (strand, locked_at nulls first, priority, run_at, failed_at nulls first, queue)")
    else
      add_index :delayed_jobs, %w(strand locked_at priority run_at failed_at queue), :name => 'get_delayed_jobs_index'
    end
  end

  def self.down
    remove_index :delayed_jobs, :name => 'get_delayed_jobs_index'

    case connection.adapter_name
    when 'PostgreSQL'
      # "nulls first" syntax is postgresql specific, and allows for more
      # efficient querying for the next job
      connection.execute("CREATE INDEX get_delayed_jobs_index ON delayed_jobs (priority, run_at, failed_at nulls first, locked_at nulls first, queue)")
    else
      add_index :delayed_jobs, %w(priority run_at locked_at failed_at queue), :name => 'get_delayed_jobs_index'
    end
    add_index :delayed_jobs, :strand
  end
end
