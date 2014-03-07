class DisallowNullOnContextModuleProgressionLockVersionColumn < ActiveRecord::Migration
  tag :predeploy

  def self.up
    ContextModuleProgression.where(lock_version: nil).update_all(lock_version: 0)
    change_column_null :context_module_progressions, :lock_version, false
  end

  def self.down
    change_column_null :context_module_progressions, :lock_version, true
  end
end
