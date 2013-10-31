class SetRoleOverrideColumnsNotNull < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    RoleOverride.where(enabled: nil).update_all(enabled: false)
    RoleOverride.where(locked: nil).update_all(locked: false)
    change_column :role_overrides, :enabled, :bool, default: true, null: false
    change_column :role_overrides, :locked, :bool, default: false, null: false
  end

  def self.down
    change_column :role_overrides, :enabled, :bool, default: nil, null: true
    change_column :role_overrides, :locked, :bool, default: nil, null: true
  end
end
