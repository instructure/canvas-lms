class AddBarToPartmanAnimals < CanvasPartman::Migration
  self.base_class = Animal

  def change
    with_each_partition do |table_name|
      change_table(table_name) do |t|
        t.string :bar
      end
    end
  end
end