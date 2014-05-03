class MakeNotificationPolicyFrequencyNotNull < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    change_column_null_with_less_locking :notification_policies, :frequency
    change_column_default :notification_policies, :frequency, 'immediately'
  end

  def self.down
    change_column :notification_policies, :frequency, :string, default: nil, null: true
  end
end
