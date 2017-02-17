class AddVericiteEnabledToAssignments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :assignments, :vericite_enabled, :boolean
  end
end
