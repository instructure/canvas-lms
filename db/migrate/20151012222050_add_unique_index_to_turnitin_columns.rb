class AddUniqueIndexToTurnitinColumns < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :assignments, :turnitin_id, unique: true, algorithm: :concurrently, where: "turnitin_id IS NOT NULL"
    add_index :users, :turnitin_id, unique: true, algorithm: :concurrently, where: "turnitin_id IS NOT NULL"
  end
end
