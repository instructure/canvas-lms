class PopulateConversationParticipantPrivateHash < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::PopulateConversationParticipantPrivateHash.send_later_if_production(:run)
  end
end
