require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_context "in-process server selenium tests"
  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }

  before do
    conversation_setup
    @s1 = user(name: "first student")
    @s2 = user(name: "second student")
    [@s1, @s2].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  context "Course with Faculty Journal not enabled" do
    it "should allow a site admin to enable faculty journal", priority: "2", test_id: 75005 do
      site_admin_logged_in
      get account_settings_url
      f('#account_enable_user_notes').click
      f('.btn.btn-primary[type="submit"]').click
      wait_for_ajaximations
      expect(is_checked('#account_enable_user_notes')).to be_truthy
    end
  end

  context "Faculty Journal" do
    before(:each) do
      @course.account.update_attribute(:enable_user_notes, true)
      user_session(@teacher)
      get_conversations
    end

    it "should be allowed on new private conversations with students", priority: "1", test_id: 207094 do
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

    it "should be allowed with student groups", priority: "1", test_id: 207093 do
      compose course: @course, to: [@group], body: 'hallo!', send: false

      checkbox = f(".user_note")
      expect(checkbox).to be_displayed
      checkbox.click

      count1 = @s1.user_notes.count
      click_send
      expect(@s1.user_notes.reload.count).to eq count1 + 1
    end

    it "should not be allowed if disabled", priority: "1", test_id: 207092 do
      @course.account.update_attribute(:enable_user_notes, false)
      get_conversations
      compose course: @course, to: [@s1], body: 'hallo!', send: false
      expect(f(".user_note")).not_to be_displayed
    end

    it "should not be allowed for students", priority: "1", test_id: 138686 do
      user_session(@s1)
      get_conversations
      compose course: @course, to: [@s2], body: 'hallo!', send: false
      expect(f(".user_note")).not_to be_displayed
    end

    it "should not be allowed with non-student recipient", priority: "1", test_id: 138687 do
      compose course: @course, to: [@teacher], body: 'hallo!', send: false
      expect(f(".user_note")).not_to be_displayed
    end

    it "should send a message with faculty journal checked", priority: "1", test_id: 75433 do
      get_conversations
      # First verify teacher can send a message with faculty journal entry checked to one student
      compose course: @course, to: [@s1], body: 'hallo!', send: false
      f('.user_note').click
      click_send
      expect(flash_message_present?(:success, /Message sent!/)).to be_truthy
      # Now verify adding another user while the faculty journal entry checkbox is checked doesn't uncheck it and
      #   still lets teacher know it was sent successfully.
      compose course: @course, to: [@s1], body: 'hallo!', send: false
      f('.user_note').click
      add_message_recipient(@s2)
      expect(is_checked('.user_note')).to be_truthy
      click_send
      expect(flash_message_present?(:success, /Message sent!/)).to be_truthy
    end
  end
end


