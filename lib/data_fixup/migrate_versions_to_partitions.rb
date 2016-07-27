module DataFixup::MigrateVersionsToPartitions
  def self.run
    partman = CanvasPartman::PartitionManager.create(Version)

    partman.migrate_data_to_partitions
  end
end