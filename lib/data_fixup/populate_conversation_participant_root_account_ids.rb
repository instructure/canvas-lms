class DataFixup::PopulateConversationParticipantRootAccountIds
  def self.run
    scope = ConversationParticipant.where(:root_account_ids => nil)
    scope = scope.joins(:conversation).where("conversations.root_account_ids IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      scope.where(:conversation_participants => { :id => min..max }).
          update_all("root_account_ids=conversations.root_account_ids")
    end
  end
end
