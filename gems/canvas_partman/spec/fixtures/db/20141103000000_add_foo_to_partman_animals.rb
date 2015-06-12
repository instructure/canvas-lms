class AddFooToPartmanAnimals < CanvasPartman::Migration
  self.base_class = Animal

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