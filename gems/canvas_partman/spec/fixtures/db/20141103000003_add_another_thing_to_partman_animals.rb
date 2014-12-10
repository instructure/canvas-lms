module CanvasPartmanTest
  AnimalAlias = Animal
end

class AddAnotherThingToPartmanAnimals < CanvasPartman::Migration
  self.master_table = 'partman_animals'
  self.base_class = CanvasPartmanTest::AnimalAlias

  def self.up
    with_each_partition do |partition_table_name|
      add_column partition_table_name, :another_thing, :string
    end
  end

  def self.down
    with_each_partition do |partition_table_name|
      remove_column partition_table_name, :another_thing, :string
    end
  end
end