class MakeNotificationPolicyFrequencyNotNull < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    change_column_null :notification_policies, :frequency, false
    change_column_default :notification_policies, :frequency, 'immediately'
  end

  def self.down
    change_column :notification_policies, :frequency, :string, default: nil, null: true
  end
end
