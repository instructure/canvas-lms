class CreateRetainedData < ActiveRecord::Migration
  tag :predeploy
  def change
    create_table :retained_data do |t|
      t.references :user
      t.string :name
      t.text :value

      t.timestamps
    end
    add_index :retained_data, :user_id
  end
end
