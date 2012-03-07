class RemoveDuplicateNotificationPolicies < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::RemoveDuplicateNotificationPolicies.send_later_if_production(:run)
  end
end
