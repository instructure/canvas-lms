class AddBarToPartmanAnimals < CanvasPartman::Migration
  self.master_table = :partman_animals

  def change
    with_each_partition do |table_name|
      change_table(table_name) do |t|
        t.string :bar
      end
    end
  end
end