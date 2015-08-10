require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_context "in-process server selenium tests"

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  describe "replying" do
    before do
      cp = conversation(@s1, @teacher, @s2, workflow_state: 'unread')
      @convo = cp.conversation
      @convo.update_attribute(:subject, 'homework')
      @convo.add_message(@s1, "What's this week's homework?")
      @convo.add_message(@s2, "I need the homework too.")
    end

    it "should maintain context and subject", priority: "1", test_id: 138696 do
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      expect(fj('#compose-message-course')).to have_attribute(:disabled, 'true')
      expect(fj('#compose-message-course')).to have_value(@course.id.to_s)
      expect(fj('#compose-message-subject')).to have_attribute(:disabled, 'true')
      expect(fj('#compose-message-subject')).not_to be_displayed
      expect(fj('#compose-message-subject')).to have_value(@convo.subject)
      expect(fj('.message_subject_ro')).to be_displayed
      expect(fj('.message_subject_ro').text).to eq @convo.subject
    end

    it "should address replies to the most recent author by default", priority: "2", test_id: 197538 do
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      expect(ffj('input[name="recipients[]"]').length).to eq 1
      expect(fj('input[name="recipients[]"]')).to have_value(@s2.id.to_s)
    end

    it "should add new messages to the conversation", priority: "1", test_id: 197537 do
      get_conversations
      initial_message_count = @convo.conversation_messages.length
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      set_message_body('Read chapters five and six.')
      click_send
      wait_for_ajaximations
      expect(ffj('.message-item-view').length).to eq initial_message_count + 1
      @convo.reload
      expect(@convo.conversation_messages.length).to eq initial_message_count + 1
    end

    it "should not allow adding recipients to private messages" do
      @convo.update_attribute(:private_hash, '12345')
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      expect(fj('#recipient-row')).to have_attribute(:style, 'display: none;')
    end
  end
end
