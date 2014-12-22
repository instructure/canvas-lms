class AddRaceIndexToPartmanAnimals < CanvasPartman::Migration
  self.master_table = 'partman_animals'

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