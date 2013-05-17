class PopulateConversationParticipantPrivateHash < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateConversationParticipantPrivateHash.send_later_if_production(:run)
  end
end
