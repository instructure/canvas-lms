class PeerReviewInvitationNeedsNotification < ActiveRecord::Migration
  tag :predeploy

  def self.up
    return unless Shard.current == Shard.default
    Canvas::MessageHelper.create_notification({
      name: 'Peer Review Invitation',
      delay_for: 0,
      category: 'Invitation'
    })
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.find_by_name('Peer Review Invitation').destroy
  end
end
