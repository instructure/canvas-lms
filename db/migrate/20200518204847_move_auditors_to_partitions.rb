class MoveAuditorsToPartitions < ActiveRecord::Migration[5.2]
  tag :postdeploy

  def up
    strand_name = "partition_auditors:#{Shard.current.database_server.id}"
    DataFixup::Auditors::MigrateAuthToPartitions.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOWER_PRIORITY,
      strand: strand_name)
    DataFixup::Auditors::MigrateCoursesToPartitions.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOWER_PRIORITY,
      strand: strand_name)
    DataFixup::Auditors::MigrateGradeChangesToPartitions.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOWER_PRIORITY,
      strand: strand_name)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
