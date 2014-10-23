class AddConversationCreatedNotification < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
                                                name: 'Conversation Created',
                                                delay_for: 0,
                                                category: 'Conversation Created'
                                              })
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.find_by_name('Conversation Created').destroy
  end
end