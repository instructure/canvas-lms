class AddUniqueIndexOnNotifications < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    return unless Shard.current.default?
    # the excess subquery is necessary to avoid error 1093 on mysql
    Notification.where("id NOT IN (SELECT * FROM (SELECT MIN(id) FROM notifications GROUP BY name) x)").delete_all
    add_index :notifications, [:name], :unique => true, :name => "index_notifications_unique_on_name"
  end

  def self.down
    return unless Shard.current.default?
    remove_index :notifications, :name => "index_notifications_unique_on_name"
  end
end
