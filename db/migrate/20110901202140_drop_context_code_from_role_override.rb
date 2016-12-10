class DropContextCodeFromRoleOverride < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_index :role_overrides, :context_code
    remove_column :role_overrides, :context_code
  end

  def self.down
    add_column :role_overrides, :context_code, :string
    add_index :role_overrides, :context_code
    RoleOverride.update_all("context_code=LOWER(context_type) || '_' || context_id")
  end
end
