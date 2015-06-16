class DataFixup::PopulateConversationParticipantPrivateHash
  def self.run
    target = %w{MySQL Mysql2}.include?(ConversationParticipant.connection.adapter_name) ? 'conversation_participants.private_hash' : 'private_hash'
    scope = ConversationParticipant.where(:private_hash => nil)
    scope = scope.joins(:conversation).where("conversations.private_hash IS NOT NULL")
    scope.find_ids_in_ranges do |min, max|
      ConversationParticipant.where(:conversation_participants => { :id => min..max }).
          update_all("#{target}=conversations.private_hash")
    end
  end
end
