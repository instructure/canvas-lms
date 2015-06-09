class AddRaceIndexToPartmanAnimals < CanvasPartman::Migration
  self.base_class = Animal

  def self.up
    with_each_partition do |partition_table_name|
      add_index partition_table_name, :race
    end
  end

  def self.down
    with_each_partition do |partition_table_name|
      remove_index partition_table_name, :race
    end
  end
end