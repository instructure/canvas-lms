class CreateAccountNotifications < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :account_notifications do |t|
      t.string :subject
      t.string :icon, :default => 'warning'
      t.text :message
      t.integer :account_id, :limit => 8
      t.integer :user_id, :limit => 8
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps null: true
    end
    add_index :account_notifications, [:account_id, :start_at]
  end

  def self.down
    drop_table :account_notifications
  end
end
