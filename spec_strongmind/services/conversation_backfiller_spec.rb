require_relative '../rails_helper'

RSpec.describe ConversationBackfiller, skip: 'todo: fix for running under LMS' do
  include_context 'stubbed_network'

  describe '.call' do
    it do
      conversation = Conversation.create
      user1 = User.create
      user2 = User.create

      conversation.conversation_messages.create author: user1
      conversation.conversation_participants.create
      conversation.conversation_participants.create

      expect(PipelineService).to receive(:publish).with(an_instance_of(Conversation))
      expect(PipelineService).to receive(:publish).with(an_instance_of(ConversationMessage)).once
      expect(PipelineService).to receive(:publish).with(an_instance_of(ConversationParticipant)).twice

      ConversationBackfiller.call
    end
  end
end
