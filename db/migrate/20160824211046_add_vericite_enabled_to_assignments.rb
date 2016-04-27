class AddVericiteEnabledToAssignments < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :assignments, :vericite_enabled, :boolean
  end
end
