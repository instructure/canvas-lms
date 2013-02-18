class PopulateConversationParticipantRootAccountIds < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateConversationParticipantRootAccountIds.send_later_if_production(:run)
  end
end
