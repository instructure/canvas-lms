class CreateAccountNotificationRoles < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :account_notification_roles do |t|
      t.integer :account_notification_id, :limit => 8, :null => false
      t.string :role_type, :null => false
    end
    add_index :account_notification_roles, [:account_notification_id, :role_type], :unique => true, :name => "idx_acount_notification_roles"
    add_foreign_key :account_notification_roles, :account_notifications
  end

  def self.down
    drop_table :account_notification_roles
  end
end
