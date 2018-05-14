class RenameSwitchmanShardsFkIfNecessary < ActiveRecord::Migration[5.1]
  tag :predeploy

  def up
    if connection.send(:postgresql_version) >= 90400
      alter_constraint(:switchman_shards, find_foreign_key(:switchman_shards, :switchman_shards, column: :delayed_jobs_shard_id), new_name: 'fk_rails_45bd80a9c8')
    else
      remove_foreign_key_if_exists :switchman_shards, column: :delayed_jobs_shard_id
      add_foreign_key :switchman_shards, :switchman_shards, column: :delayed_jobs_shard_id
    end

  end
end
