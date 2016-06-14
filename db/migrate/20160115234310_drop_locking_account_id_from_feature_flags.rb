class DropLockingAccountIdFromFeatureFlags < ActiveRecord::Migration
  tag :postdeploy

  def change
    remove_column :feature_flags, :locking_account_id, :integer, limit: 8
  end
end
