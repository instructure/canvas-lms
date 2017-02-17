class AddConversationCreatedNotification < ActiveRecord::Migration[4.2]
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
    Notification.where(name: 'Conversation Created').delete_all
  end
end
