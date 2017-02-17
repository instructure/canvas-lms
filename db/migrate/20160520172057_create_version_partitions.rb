class CreateVersionPartitions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    partman = CanvasPartman::PartitionManager.create(Version)
    partman.create_initial_partitions(Version::Partitioner.precreate_tables)
  end

  def down
    partman = CanvasPartman::PartitionManager.create(Version)
    partman.partition_tables.each do |partition|
      drop_table partition
    end
  end
end
