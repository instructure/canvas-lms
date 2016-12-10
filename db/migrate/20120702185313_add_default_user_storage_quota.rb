class AddDefaultUserStorageQuota < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :accounts, :default_user_storage_quota, :bigint
  end

  def self.down
    remove_column :accounts, :default_user_storage_quota
  end
end
