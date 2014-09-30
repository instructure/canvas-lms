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
    Notification.find_by_name('Announcement Created By You').try(:destroy)
    Notification.find_by_name('Announcement Reply').try(:destroy)
  end
end
