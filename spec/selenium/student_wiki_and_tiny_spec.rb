require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  include_examples "in-process server selenium tests"

  context "as a student" do

    before(:each) do
      course_with_student_logged_in
      set_course_draft_state
    end

    def set_notification_policy
      n = Notification.create(:name => "Updated Wiki Page", :category => "TestImmediately")
      NotificationPolicy.create(:notification => n, :communication_channel => @user.communication_channel, :frequency => "immediately")
    end

    def update_wiki_attr(days_old, notify, body, p)
      p.created_at = days_old.days.ago
      p.notify_of_update = notify
      p.save!
      p.update_attributes(:body => body)
    end

    it "should not allow access to page when marked as hide from student" do
      expected_error = "Unauthorized"
      title = "test_page"
      hfs = true
      edit_roles = "members"

      create_wiki_page(title, hfs, edit_roles)
      get "/courses/#{@course.id}/pages/#{title}"
      wait_for_ajax_requests

      expect(f('.ui-state-error')).to include_text(expected_error)
    end

    it "should not allow students to edit if marked for only teachers can edit" do
      #vars for the create_wiki_page method which seeds the used page
      title = "test_page"
      hfs = false
      edit_roles = "teachers"

      create_wiki_page(title, hfs, edit_roles)
      get "/courses/#{@course.id}/pages/#{title}"
      wait_for_ajax_requests

      expect(f('a.edit-wiki')).to be_nil
    end

    it "should allow students to edit wiki if any option but teachers is selected" do
      title = "test_page"
      hfs = false
      edit_roles = "public"

      create_wiki_page(title, hfs, edit_roles)

      get "/courses/#{@course.id}/pages/#{title}"
      wait_for_ajax_requests

      expect(f('a.edit-wiki')).to be_displayed

      #vars for 2nd wiki page with different permissions
      title2 = "test_page2"
      edit_roles2 = "members"

      create_wiki_page(title2, hfs, edit_roles2)

      get "/courses/#{@course.id}/pages/#{title2}"
      wait_for_ajax_requests

      expect(f('a.edit-wiki')).to be_displayed
    end

    it "should notify users when wiki page gets changed" do
      set_notification_policy

      #vars for the create_wiki_page method which seeds the used page
      title = "test_page"
      hfs = false
      edit_roles = "members"
      #vars for update_wiki_attrib method
      days_old = 1
      notify = true
      body = "test"

      p = create_wiki_page(title, hfs, edit_roles)
      update_wiki_attr(days_old, notify, body, p)

      #validation that the update to the body triggered a notification to the @user as expected
      expect(p.messages_sent).not_to be_nil
      expect(p.messages_sent).not_to be_empty
      expect(p.messages_sent["Updated Wiki Page"]).not_to be_nil
      expect(p.messages_sent["Updated Wiki Page"]).not_to be_empty
      expect(p.messages_sent["Updated Wiki Page"].map(&:user)).to be_include(@user)
    end

    it "should not notify users when wiki page gets changed" do
      set_notification_policy

      #vars for the create_wiki_page method which seeds the used page
      title = "test_page"
      hfs = false
      edit_roles = "members"
      #vars for update_wiki_attrib method
      days_old = 1
      notify = false
      body = "test"

      p = create_wiki_page(title, hfs, edit_roles)
      update_wiki_attr(days_old, notify, body, p)

      #validation that the update to the body did not trigger a notification to the @user as expected
      expect(p.messages_sent).to be_empty
    end
  end
end
