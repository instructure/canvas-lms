class AddAnnouncementCreatedNotification < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
                                                name: 'Announcement Created By You',
                                                delay_for: 0,
                                                  category: 'Announcement Created By You'
                                              })
    Canvas::MessageHelper.create_notification({
                                                name: 'Announcement Reply',
                                                delay_for: 0,
                                                  category: 'Announcement Created By You'
                                              })
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.where(name: 'Announcement Created By You').delete_all
    Notification.where(name: 'Announcement Reply').delete_all
  end
end
