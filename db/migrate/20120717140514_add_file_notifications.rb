class AddFileNotifications < ActiveRecord::Migration
  tag :predeploy

  def self.up
    Notification.create(:name => "New File Added", :category => "Files")
    Notification.create(:name => "New Files Added", :category => "Files")
  end

  def self.down
    Notification.find_by_name("New File Added").try(:destroy)
    Notification.find_by_name("New Files Added").try(:destroy)
  end
end
