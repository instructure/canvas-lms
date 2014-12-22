class AddFooToPartmanAnimals < CanvasPartman::Migration
  self.master_table = :partman_animals

  def self.up
    with_each_partition do |partition_table_name|
      add_column partition_table_name, :foo, :string
    end
  end

  def self.down
    with_each_partition do |partition_table_name|
      remove_column partition_table_name, :foo, :string
    end
  end
end