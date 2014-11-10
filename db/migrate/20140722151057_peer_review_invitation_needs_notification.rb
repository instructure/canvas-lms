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
    Notification.where(name: 'Peer Review Invitation').delete_all
  end
end
