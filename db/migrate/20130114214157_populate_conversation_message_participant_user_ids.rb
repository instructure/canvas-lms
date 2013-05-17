class PopulateConversationMessageParticipantUserIds < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateConversationMessageParticipantUserIds.send_later_if_production(:run)
  end
end
