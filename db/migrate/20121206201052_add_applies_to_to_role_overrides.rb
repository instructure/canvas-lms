class AddAppliesToToRoleOverrides < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :role_overrides, :applies_to_self, :boolean, :default => true, :null => false
    add_column :role_overrides, :applies_to_descendants, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :role_overrides, :applies_to_self, :applies_to_descendants
  end
end
