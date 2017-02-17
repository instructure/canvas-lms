class SetRoleOverrideColumnsNotNull < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    RoleOverride.where(enabled: nil).preload(:context, :role).find_each do |ro|
      # can't simply set to false, since it was conflated with being for inheritance
      # in RoleOverride.permission_for
      ro.enabled = RoleOverride.enabled_for?(ro.context, ro.permission.to_sym, ro.role).include?(:self)
      ro.save!
    end

    RoleOverride.where(locked: nil).update_all(locked: false)

    change_column :role_overrides, :enabled, :bool, default: true, null: false
    change_column :role_overrides, :locked, :bool, default: false, null: false
  end

  def self.down
    change_column :role_overrides, :enabled, :bool, default: nil, null: true
    change_column :role_overrides, :locked, :bool, default: nil, null: true
  end
end
