require_relative '../rails_helper'

RSpec.describe ConversationMessage do
  include_context "stubbed_network"

  describe '#delete' do
    it 'should publish the delete to the pipeline' do
      course_with_teacher(:active_all => true)

      @student           = student_in_course(:active_all => true).user
      @convo_participant = @teacher.initiate_conversation([@student])
      user               = User.find(@convo_participant.user_id)
      @account           = Account.find(user.account.id)

      expect(PipelineService).to receive(:publish)

      @convo_participant.add_message("message", { root_account_id: @account.id })
      @convo_participant.conversation.conversation_messages.last.destroy
    end
  end
end
