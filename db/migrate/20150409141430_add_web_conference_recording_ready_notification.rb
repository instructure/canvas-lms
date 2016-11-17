class AddWebConferenceRecordingReadyNotification < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
      name: 'Web Conference Recording Ready',
      delay_for: 0,
      category: 'Recording Ready'
    })
  end

  def down
    return unless Shard.current == Shard.default
    Notification.where(name: 'Web Conference Recording Ready').delete_all
  end
end
