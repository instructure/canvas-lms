require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/assignment_overrides')

describe "conversations new" do
  include_context "in-process server selenium tests"
  include AssignmentOverridesSeleniumHelper
  include ConversationsCommon

  let(:account) { Account.default }
  let(:account_settings_url) { "/accounts/#{account.id}/settings" }
  let(:user_notes_url) { "/courses/#{@course.id}/user_notes"}
  let(:student_user_notes_url) {"/users/#{@s1.id}/user_notes"}

  before do
    conversation_setup
    @s1 = user_factory(name: "first student")
    @s2 = user_factory(name: "second student")
    @s3 = user_factory(name: 'third student')
    [@s1, @s2, @s3].each { |s| @course.enroll_student(s).update_attribute(:workflow_state, 'active') }
    cat = @course.group_categories.create(:name => "the groups")
    @group = cat.groups.create(:name => "the group", :context => @course)
    @group.users = [@s1, @s2]
  end

  context "Course with Faculty Journal not enabled" do
    before(:each) do
      site_admin_logged_in
    end

    it "should allow a site admin to enable faculty journal", priority: "2", test_id: 75005 do
      get account_settings_url
      f('#account_enable_user_notes').click
      f('.Button.Button--primary[type="submit"]').click
      wait_for_ajaximations
      expect(is_checked('#account_enable_user_notes')).to be_truthy
    end
  end

  context "Course with Faculty Journal enabled" do
    before(:each) do
      site_admin_logged_in
      @course.account.update_attribute(:enable_user_notes, true)
    end

    it "should check the Journal messages for correct time and sender", priority: "1", test_id: 75701 do
      user_session(@teacher)
      conversations
      compose course: @course, subject: 'Christmas', to: [@s1], body: 'The Fat Man cometh.', journal: true, send: true
      time = format_time_for_view(UserNote.last.updated_at)
      remove_user_session
      get student_user_notes_url
      expect(f('.subject')).to include_text('Christmas')
      expect(f('.user_content').text).to eq 'The Fat Man cometh.'
      expect(f('.creator_name')).to include_text(@teacher.name)
      expect(f('.creator_name')).to include_text(time)
    end

    it "should allow an admin to delete a Journal message", priority: "1", test_id: 75703 do
      user_session(@teacher)
      conversations
      compose course: @course, subject: 'Christmas', to: [@s1], body: 'The Fat Man cometh.', journal: true, send: true
      remove_user_session
      get student_user_notes_url
      f('.delete_link').click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f('.title.subject').text).to eq('')
      get student_user_notes_url
      expect(f('.title.subject').text).to eq('')
    end

    it "should allow a new entry by an admin", priority: "1", test_id: 75702 do
      get student_user_notes_url
      f('#new_user_note_button').click
      replace_content(f('#user_note_title'),'FJ Title 2')
      replace_content(f('textarea'),'FJ Body text 2')
      wait_for_ajaximations
      f('.send_button').click
      wait_for_ajaximations
      time = format_time_for_view(UserNote.last.updated_at)
      get student_user_notes_url
      expect(f('.subject').text).to eq 'FJ Title 2'
      expect(f('.user_content').text).to eq 'FJ Body text 2'
      expect(f('.creator_name')).to include_text(time)
    end

    it "should clear the subject and body when cancel is clicked", priority: "1", test_id: 458518
  end

  context "Faculty Journal" do
    before(:each) do
      @course.account.update_attribute(:enable_user_notes, true)
      user_session(@teacher)
      conversations
    end

    it "should go to the user_notes page", priority: "1", test_id: 133090 do
      get user_notes_url
      expect(f('#breadcrumbs')).to include_text('Faculty Journal')
    end

    it "should be allowed on new private conversations with students", priority: "1", test_id: 207094 do
      compose course: @course, to: [@s1, @s2], body: 'hallo!', send: false
      checkbox = f('.user_note')
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
      checkbox = f('.user_note')
      expect(checkbox).to be_displayed
      checkbox.click
      count1 = @s1.user_notes.count
      click_send
      expect(@s1.user_notes.reload.count).to eq count1 + 1
    end

    it "should not be allowed if disabled", priority: "1", test_id: 207092 do
      @course.account.update_attribute(:enable_user_notes, false)
      conversations
      compose course: @course, to: [@s1], body: 'hallo!', send: false
      expect(f('.user_note')).not_to be_displayed
    end

    it "should not be allowed for students", priority: "1", test_id: 138686 do
      user_session(@s1)
      conversations
      compose course: @course, to: [@s2], body: 'hallo!', send: false
      expect(f('.user_note')).not_to be_displayed
    end

    it "should not be allowed with non-student recipient", priority: "1", test_id: 138687 do
      compose course: @course, to: [@teacher], body: 'hallo!', send: false
      expect(f('.user_note')).not_to be_displayed
    end

    it "should have the Journal entry checkbox come back unchecked", priority: "1", test_id: 523385 do
      skip_if_chrome('Fragile in Chrome')
      f('#compose-btn').click
      wait_for_ajaximations
      expect(f('.user_note')).not_to be_displayed

      select_message_course(@course)
      add_message_recipient(@s1)
      write_message_body('Give the Turkey his day')

      expect(f('.user_note')).to be_displayed
      add_message_recipient(@s2)
      checkbox = f('.user_note')
      expect(checkbox).to be_displayed
      checkbox.click
      expect(is_checked('.user_note')).to be_present
      hover_and_click('.ac-token-remove-btn')
      expect(f('.user_note')).not_to be_displayed
      add_message_recipient(@s3)
      expect(is_checked('.user_note')).not_to be_present
    end

    it "should have the Journal entry checkbox visible", priority: "1", test_id: 75008 do
      skip_if_chrome('Fragile in Chrome')
      f('#compose-btn').click
      wait_for_ajaximations
      expect(f('.user_note')).not_to be_displayed

      select_message_course(@course)
      add_message_recipient(@s1)
      write_message_body('Give the Turkey his day')
      expect(f('.user_note')).to be_displayed
      add_message_recipient(@s2)
      expect(f('.user_note')).to be_displayed
    end

    it "should not have the Faculty Journal entry checkbox visible", priority: "1", test_id: 523384 do
      skip('Currently broken and shelved CNVS-17248')
      f('#compose-btn').click
      expect(f('.user_note')).not_to be_displayed
      compose course: @course, to: [@s1, @s2, @s3], body: 'Give the Turkey his day', send: false
      expect(f('.user_note')).not_to be_displayed
    end

    it "should send a message with faculty journal checked", priority: "1", test_id: 75433 do
      conversations
      # First verify teacher can send a message with faculty journal entry checked to one student
      compose course: @course, to: [@s1], body: 'hallo!', journal: true, send: true
      expect_flash_message :success, /Message sent!/
      # Now verify adding another user while the faculty journal entry checkbox is checked doesn't uncheck it and
      #   still lets teacher know it was sent successfully.
      fj('.ic-flash-success:last').click
      compose course: @course, to: [@s1], body: 'hallo!', journal: true, send: false
      add_message_recipient(@s2)
      expect(is_checked('.user_note')).to be_truthy
      click_send
      expect_flash_message :success, /Message sent!/
    end
  end
end
