require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
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
      @convo.update_attribute(:context, @group)
      @convo.add_message(@s1, "What's this week's homework?")
      @convo.add_message(@s2, "I need the homework too.")
    end


    it "should maintain context and subject", priority: "1", test_id: 138696 do
      go_to_inbox_and_select_message
      f('#reply-btn').click
      expect(f('#compose-message-course')).to be_disabled
      expect(f('.message_course_ro').text).to eq @group.name
      expect(f('input[name=context_code]')).to have_value @group.asset_string
      expect(f('#compose-message-subject')).to be_disabled
      expect(f('#compose-message-subject')).not_to be_displayed
      expect(f('#compose-message-subject')).to have_value(@convo.subject)
      expect(f('.message_subject_ro')).to be_displayed
      expect(f('.message_subject_ro').text).to eq @convo.subject
    end

    it "should add new messages to the conversation", priority: "1", test_id: 197537 do
      initial_message_count = @convo.conversation_messages.length
      go_to_inbox_and_select_message
      f('#reply-btn').click
      write_message_body('Read chapters five and six.')
      click_send
      wait_for_ajaximations
      expect(ff('.message-item-view').length).to eq initial_message_count + 1
      @convo.reload
      expect(@convo.conversation_messages.length).to eq initial_message_count + 1
    end

    it "should not allow adding recipients to private messages", priority: "2", test_id: 1089655 do
      @convo.update_attribute(:private_hash, '12345')
      go_to_inbox_and_select_message
      f('#reply-btn').click
      expect(f('#recipient-row')).to have_attribute(:style, 'display: none;')
    end

    context "reply and reply all" do

      it "should address replies to the most recent author by default from the icon at the top of the page", priority: "2", test_id: 197538 do
        go_to_inbox_and_select_message
        f('#reply-btn').click
        assert_number_of_recipients(1)
      end

      it "should reply to all users from the reply all icon on the top of the page", priority: "2", test_id: 1070114 do
        go_to_inbox_and_select_message
        f('#reply-all-btn').click
        assert_number_of_recipients(2)
      end

      it "should reply to message from the reply icon next to the message", priority: "2", test_id: 1077516 do
        go_to_inbox_and_select_message
        f('.message-detail-actions .reply-btn').click
        assert_number_of_recipients(1)
      end

      it "should reply to all users from the settings icon next to the message", priority: "2", test_id: 86606 do
        go_to_inbox_and_select_message
        f('.message-detail-actions .icon-settings').click
        f('.ui-menu-item .reply-all-btn').click
        assert_number_of_recipients(2)
      end

      it "should reply to message from mouse hover", priority: "2", test_id: 1069285 do
        go_to_inbox_and_select_message
        driver.mouse.move_to(f('.message-content .message-item-view'))
        f('.message-info .reply-btn').click
        assert_number_of_recipients(1)
      end

      it "should reply to all from mouse hover", priority: "2", test_id: 1069836 do
        go_to_inbox_and_select_message
        driver.mouse.move_to(f('.message-content .message-item-view'))
        f('.message-info .icon-settings').click
        f('.ui-menu-item .reply-all-btn').click
        assert_number_of_recipients(2)
      end
    end

    it "should not let a student reply to a student conversation if they lose messaging permissions" do
      @convo.conversation_participants.where(:user_id => @teacher).delete_all
      @convo.update_attribute(:context, @course)
      user_session(@s1)
      go_to_inbox_and_select_message
      expect(f('#reply-btn')).to_not be_disabled

      @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)
      go_to_inbox_and_select_message
      expect(f('#reply-btn')).to be_disabled
    end

    it "should let a student reply to a conversation including a teacher even if they lose messaging permissions" do
      @convo.update_attribute(:context, @course)
      user_session(@s1)
      @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)
      go_to_inbox_and_select_message
      expect(f('#reply-btn')).to_not be_disabled
    end
  end
end

