class CreateUserModulePositions < ActiveRecord::Migration
  tag :postdeploy
  def change
    create_table :user_module_positions do |t|
      t.integer :module_item_id, :limit => 8
      t.integer :course_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.integer :module_id, :limit => 8

      t.timestamps
    end
  end
end
