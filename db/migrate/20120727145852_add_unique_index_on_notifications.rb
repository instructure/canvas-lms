class AddUniqueIndexOnNotifications < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    Notification.where("id NOT IN (SELECT * FROM (SELECT MIN(id) FROM #{Notification.quoted_table_name} GROUP BY name) x)").delete_all
    add_index :notifications, [:name], :unique => true, :name => "index_notifications_unique_on_name"
  end

  def self.down
    remove_index :notifications, :name => "index_notifications_unique_on_name"
  end
end
