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

  describe "message sending" do
    it "should start a group conversation when there is only one recipient", priority: "2", test_id: 201499 do
      get_conversations
      compose course: @course, to: [@s1], subject: 'single recipient', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('single recipient')
      expect(c.private?).to be_falsey
    end

    it "should start a group conversation when there is more than one recipient", priority: "2", test_id: 201500 do
      get_conversations
      compose course: @course, to: [@s1, @s2], subject: 'multiple recipients', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq('multiple recipients')
      expect(c.private?).to be_falsey
      expect(c.conversation_participants.collect(&:user_id).sort).to eq([@teacher, @s1, @s2].collect(&:id).sort)
    end

    it "should allow admins to send a message without picking a context", priority: "1", test_id: 138677 do
      user = account_admin_user
      user_logged_in({:user => user})
      get_conversations
      compose to: [@s1], subject: 'context-free', body: 'hallo!'
      c = @s1.conversations.last.conversation
      expect(c.subject).to eq 'context-free'
      expect(c.context).to eq Account.default
    end

    it "should not allow non-admins to send a message without picking a context", priority: "1", test_id: 138678 do
      get_conversations
      fj('#compose-btn').click
      wait_for_animations
      expect(fj('#recipient-row')).to have_attribute(:style, 'display: none;')
    end

    it "should allow non-admins to send a message to an account-level group", priority: "2", test_id: 201506 do
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

    it "should allow admins to message users from their profiles", priority: "2", test_id: 201940 do
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

    it "should allow selecting multiple recipients in one search", priority: "2", test_id: 201941 do
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

    it "should not send the message on shift-enter", priority: "1", test_id: 206019 do
      get_conversations
      compose course: @course, to: [@s1], subject: 'context-free', body: 'hallo!', send: false
      driver.action.key_down(:shift).perform
      get_message_body_input.send_keys(:enter)
      driver.action.key_up(:shift).perform
      expect(fj('#compose-new-message:visible')).not_to be_nil
    end

    #
    context "bulk_message locking" do
      before do
        # because i'm too lazy to create more users
        Conversation.stubs(:max_group_conversation_size).returns(1)
      end

      it "should check and lock the bulk_message checkbox when over the max size", priority: "2", test_id: 206022 do
        get_conversations
        compose course: @course, subject: 'lockme', body: 'hallo!', send: false

        f("#recipient-search-btn").click
        wait_for_ajaximations
        f("li.everyone").click # send to everybody in the course
        wait_for_ajaximations

        selector = "#bulk_message"
        bulk_cb = f(selector)
        
        expect(bulk_cb.attribute('disabled')).to be_present
        expect(is_checked(selector)).to be_truthy

        hover_and_click('.ac-token-remove-btn') # remove the token
        wait_for_ajaximations

        expect(bulk_cb.attribute('disabled')).to be_blank
        expect(is_checked(selector)).to be_falsey # should be unchecked
      end

      it "should leave the value the same as before after unlocking", priority: "2", test_id: 206023 do
        get_conversations
        compose course: @course, subject: 'lockme', body: 'hallo!', send: false

        selector = "#bulk_message"
        bulk_cb = f(selector)
        bulk_cb.click # check the box

        f("#recipient-search-btn").click
        wait_for_ajaximations
        f("li.everyone").click # send to everybody in the course
        wait_for_ajaximations
        hover_and_click('.ac-token-remove-btn') # remove the token
        wait_for_ajaximations

        expect(bulk_cb.attribute('disabled')).to be_blank
        expect(is_checked(selector)).to be_truthy # should still be checked
      end
    end
  end
end