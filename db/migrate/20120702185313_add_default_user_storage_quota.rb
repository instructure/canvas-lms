class AddDefaultUserStorageQuota < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :accounts, :default_user_storage_quota, :bigint
  end

  def self.down
    remove_column :accounts, :default_user_storage_quota
  end
end
