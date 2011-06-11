class OptimizeDelayedJobs < ActiveRecord::Migration
  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def self.up
    create_table :failed_jobs do |t|
      t.integer  "priority",    :default => 0
      t.integer  "attempts",    :default => 0
      t.string   "handler",     :limit => 512000
      t.integer  "original_id", :limit => 8
      t.text     "last_error"
      t.string   "queue"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string   "locked_by"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "tag"
      t.integer  "max_attempts"
      t.string   "strand"
    end

    remove_index :delayed_jobs, :name => 'get_delayed_jobs_index'
    remove_index :delayed_jobs, [:strand]

    add_index :delayed_jobs, %w(run_at queue locked_at strand priority), :name => 'index_delayed_jobs_for_get_next'
    add_index :delayed_jobs, %w(strand id), :name => 'index_delayed_jobs_on_strand'

    # move all failed jobs to the new failed table
    Delayed::Job.find_each(:conditions => 'failed_at is not null') do |job|
      job.fail! unless job.on_hold?
    end
  end

  def self.down
    remove_index :delayed_jobs, :name => 'index_delayed_jobs_for_get_next'
    remove_index :delayed_jobs, :name => 'index_delayed_jobs_on_strand'

    add_index :delayed_jobs, [:strand]
    # from CleanupDelayedJobsIndexes migration
    case connection.adapter_name
    when 'PostgreSQL'
      # "nulls first" syntax is postgresql specific, and allows for more
      # efficient querying for the next job
      connection.execute("CREATE INDEX get_delayed_jobs_index ON delayed_jobs (priority, run_at, failed_at nulls first, locked_at nulls first, queue)")
    else
      add_index :delayed_jobs, %w(priority run_at locked_at failed_at queue), :name => 'get_delayed_jobs_index'
    end

    Delayed::Job::Failed.find_each do |job|
      attrs = job.attributes
      attrs.delete('id')
      Delayed::Job.create!(attrs)
    end

    drop_table :failed_jobs
  end
end
