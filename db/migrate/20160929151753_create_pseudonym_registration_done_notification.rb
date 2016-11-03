class CreatePseudonymRegistrationDoneNotification < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
                                                name: 'Pseudonym Registration Done',
                                                delay_for: 0,
                                                category: 'Registration'
                                              })
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.where(name: 'Pseudonym Registration Done').delete_all
  end
end
