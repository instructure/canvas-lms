class DataFixup::PopulateConversationParticipantPrivateHash
  def self.run
    scope = ConversationParticipant.where(:private_hash => nil)
    scope = scope.joins(:conversation).where("conversations.private_hash IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      scope.where(:conversation_participants => { :id => min..max }).
          update_all("private_hash=conversations.private_hash")
    end
  end
end
