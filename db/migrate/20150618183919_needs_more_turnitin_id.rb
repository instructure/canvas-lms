class NeedsMoreTurnitinId < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :assignments, :turnitin_id, :integer, limit: 8
    add_column :users, :turnitin_id, :integer, limit: 8
  end
end
