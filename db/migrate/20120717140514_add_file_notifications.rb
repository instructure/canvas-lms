class AddFileNotifications < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # (shard check added later; dupes removed in AddUniqueIndexOnNotifications)
    return unless Shard.current.default?
    Notification.create!(:name => "New File Added", :category => "Files")
    Notification.create!(:name => "New Files Added", :category => "Files")
  end

  def self.down
    # (try on each shard, because there may be duplicates due to the above)
    Notification.where(name: "New File Added").delete_all
    Notification.where(name: "New Files Added").delete_all
  end
end
