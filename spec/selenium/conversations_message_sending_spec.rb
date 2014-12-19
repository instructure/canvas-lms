require File.expand_path(File.dirname(__FILE__) + '/helpers/conversations_common')

describe "conversations new" do
  include_examples "in-process server selenium tests"

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  describe "message sending" do
    it "should start a group conversation when there is only one recipient" do
      get_conversations
      compose course: @course, to: [@s1], subject: 'single recipient', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('single recipient')
      expect(c.private?).to be_falsey
    end

    it "should start a group conversation when there is more than one recipient" do
      get_conversations
      compose course: @course, to: [@s1, @s2], subject: 'multiple recipients', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('multiple recipients')
      expect(c.private?).to be_falsey
      expect(c.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2].collect(&:id).sort)
    end

    it "should allow admins to send a message without picking a context" do
      user = account_admin_user
      user_logged_in({:user => user})
      get_conversations
      compose to: [@s1], subject: 'context-free', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq 'context-free'
      expect(c.context).to eq Account.default
    end

    it "should not allow non-admins to send a message without picking a context" do
      get_conversations
      fj('#compose-btn').click
      wait_for_animations
      expect(fj('#compose-new-message .ac-input')).to have_attribute(:disabled, 'true')
    end

    it "should allow non-admins to send a message to an account-level group" do
      @group = Account.default.groups.create(:name => "the group")
      @group.add_user(@s1)
      @group.add_user(@s2)
      @group.save
      user_logged_in({:user => @s1})
      get_conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@group, true)
      add_message_recipient @s2
    end

    it "should allow admins to message users from their profiles" do
      user = account_admin_user
      user_logged_in({:user => user})
      get "/accounts/#{Account.default.id}/users"
      wait_for_ajaximations
      f('li.user a').click
      wait_for_ajaximations
      f('.icon-email').click
      wait_for_ajaximations
      expect(f('.ac-token')).not_to be_nil
    end

    it "should allow selecting multiple recipients in one search" do
      get_conversations
      fj('#compose-btn').click
      wait_for_ajaximations
      select_message_course(@course)
      get_message_recipients_input.send_keys('student')
      driver.action.key_down(modifier).perform
      keep_trying_until { fj(".ac-result:contains('first student')") }.click
      driver.action.key_up(modifier).perform
      fj(".ac-result:contains('second student')").click
      expect(ff('.ac-token').count).to eq 2
    end

    it "should not send the message on shift-enter" do
      get_conversations
      compose course: @course, to: [@s1], subject: 'context-free', body: 'hallo!', send: false
      driver.action.key_down(:shift).perform
      get_message_body_input.send_keys(:enter)
      driver.action.key_up(:shift).perform
      expect(fj('#compose-new-message:visible')).not_to be_nil
    end

    context "user notes" do
      before(:each) do
        @course.account.update_attribute(:enable_user_notes, true)
        user_session(@teacher)
        get_conversations
      end

      it "should be allowed on new private conversations with students" do
        compose course: @course, to: [@s1, @s2], body: 'hallo!', send: false

        checkbox = f(".user_note")
        expect(checkbox).to be_displayed
        checkbox.click

        count1 = @s1.user_notes.count
        count2 = @s2.user_notes.count
        click_send
        expect(@s1.user_notes.reload.count).to eq count1 + 1
        expect(@s2.user_notes.reload.count).to eq count2 + 1
      end

      it "should be allowed with student groups" do
        compose course: @course, to: [@group], body: 'hallo!', send: false

        checkbox = f(".user_note")
        expect(checkbox).to be_displayed
        checkbox.click

        count1 = @s1.user_notes.count
        click_send
        expect(@s1.user_notes.reload.count).to eq count1 + 1
      end

      it "should not be allowed if disabled" do
        @course.account.update_attribute(:enable_user_notes, false)
        get_conversations
        compose course: @course, to: [@s1], body: 'hallo!', send: false
        expect(f(".user_note")).not_to be_displayed
      end

      it "should not be allowed for students" do
        user_session(@s1)
        get_conversations
        compose course: @course, to: [@s2], body: 'hallo!', send: false
        expect(f(".user_note")).not_to be_displayed
      end

      it "should not be allowed with non-student recipient" do
        compose course: @course, to: [@teacher], body: 'hallo!', send: false
        expect(f(".user_note")).not_to be_displayed
      end
    end
  end

  describe "replying" do
    before do
      cp = conversation(@s1, @teacher, @s2, workflow_state: 'unread')
      @convo = cp.conversation
      @convo.update_attribute(:subject, 'homework')
      @convo.add_message(@s1, "What's this week's homework?")
      @convo.add_message(@s2, "I need the homework too.")
    end

    it "should maintain context and subject" do
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

    it "should address replies to the most recent author by default" do
      get_conversations
      conversation_elements[0].click
      wait_for_ajaximations
      fj('#reply-btn').click
      expect(ffj('input[name="recipients[]"]').length).to eq 1
      expect(fj('input[name="recipients[]"]')).to have_value(@s2.id.to_s)
    end

    it "should add new messages to the conversation" do
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
      expect(fj('.compose_form .ac-input-box.disabled')).not_to be_nil
    end
  end
end