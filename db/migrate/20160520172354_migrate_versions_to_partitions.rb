class MigrateVersionsToPartitions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::MigrateVersionsToPartitions.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOWER_PRIORITY,
      max_attempts: 1,
      strand: "partition_versions:#{Shard.current.database_server.id}")
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
