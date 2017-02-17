class PopulateConversationMessageParticipantUserIds < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::PopulateConversationMessageParticipantUserIds.send_later_if_production(:run)
  end
end
