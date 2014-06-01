class DisallowNullOnContextModuleProgressionLockVersionColumn < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column_null :context_module_progressions, :lock_version, false
  end

  def self.down
    change_column_null :context_module_progressions, :lock_version, true
  end
end
