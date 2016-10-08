require_relative '../sharding_spec_helper'

describe DataFixup::FixConversationRootAccountIds do
  specs_require_sharding

  it 'should fix conversations with unglobalishized root account ids' do
    @shard1.activate do
      @account = account_model
      new_course = course(:account => @account)
      u1 = user
      u2 = user
      conversation = Conversation.initiate([u1, u2], false, context_type: 'Course', context_id: new_course.id)
      conversation.root_account_ids = [@account.id] # unglobalize it
      conversation.save!

      part = conversation.conversation_participants.first
      part.root_account_ids = @account.id.to_s
      part.save!

      DataFixup::FixConversationRootAccountIds.run

      conversation.reload
      expect(conversation.root_account_ids).to eql [@account.global_id]

      part.reload
      expect(part.root_account_ids).to eql @account.global_id.to_s
    end
  end
end
