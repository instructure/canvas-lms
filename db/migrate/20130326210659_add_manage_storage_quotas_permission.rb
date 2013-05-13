class AddManageStorageQuotasPermission < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::CopyRoleOverrides.send_later_if_production_enqueue_args(:run,
      {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1},
      :manage_account_settings, :manage_storage_quotas)
  end

  def self.down
  end
end
