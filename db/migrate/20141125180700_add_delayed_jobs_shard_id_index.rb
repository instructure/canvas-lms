class AddDelayedJobsShardIdIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def change
    add_index :delayed_jobs, :shard_id, algorithm: :concurrently
  end
end
