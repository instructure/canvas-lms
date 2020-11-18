class MoveAuditorsToPartitions < ActiveRecord::Migration[5.2]
  tag :postdeploy

  def up
    strand_name = "partition_auditors:#{Shard.current.database_server.id}"
    DataFixup::Auditors::MigrateAuthToPartitions.delay_if_production(priority: Delayed::LOWER_PRIORITY, strand: strand_name).run
    DataFixup::Auditors::MigrateCoursesToPartitions.delay_if_production(priority: Delayed::LOWER_PRIORITY, strand: strand_name).run
    DataFixup::Auditors::MigrateGradeChangesToPartitions.delay_if_production(priority: Delayed::LOWER_PRIORITY, strand: strand_name).run
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
