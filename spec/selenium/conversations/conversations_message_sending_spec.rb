require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

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
      expect(fj('#recipient-row')).to have_attribute(:style, 'display: none;')
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
  end
end