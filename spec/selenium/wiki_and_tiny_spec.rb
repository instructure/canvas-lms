require File.expand_path(File.dirname(__FILE__) + '/helpers/wiki_and_tiny_common')

describe "Wiki pages and Tiny WYSIWYG editor" do
  it_should_behave_like "wiki and tiny selenium tests"

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should add a quiz to the rce" do
      #create test quiz
      @context = @course
      quiz = quiz_model
      quiz.generate_quiz_data
      quiz.save!

      get "/courses/#{@course.id}/wiki"
      # add quiz to rce
      accordion = f('#pages_accordion')
      accordion.find_element(:link, I18n.t('links_to.quizzes', 'Quizzes')).click
      keep_trying_until { accordion.find_element(:link, quiz.title).should be_displayed }
      accordion.find_element(:link, quiz.title).click
      in_frame "wiki_page_body_ifr" do
        f('#tinymce').should include_text(quiz.title)
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests

      f('#wiki_body').find_element(:link, quiz.title).should be_displayed
    end

    it "should add an assignment to the rce" do
      assignment_name = 'first assignment'
      @assignment = @course.assignments.create(:name => assignment_name)
      get "/courses/#{@course.id}/wiki"

      f('.wiki_switch_views_link').click
      clear_wiki_rce
      f('.wiki_switch_views_link').click
      #check assignment accordion
      accordion = f('#pages_accordion')
      accordion.find_element(:link, I18n.t('links_to.assignments', 'Assignments')).click
      keep_trying_until { accordion.find_element(:link, assignment_name).should be_displayed }
      accordion.find_element(:link, assignment_name).click
      in_frame "wiki_page_body_ifr" do
        f('#tinymce').should include_text(assignment_name)
      end

      submit_form('#new_wiki_page')
      wait_for_ajax_requests
      get "/courses/#{@course.id}/wiki" #can't just wait for the dom, for some reason it stays in edit mode
      wait_for_ajax_requests
      f('#wiki_body').find_element(:css, "a[title='#{assignment_name}']").should be_displayed
    end

    ['Only Teachers', 'Teacher and Students', 'Anyone'].each_with_index do |permission, i|
      it "should validate correct permissions for #{permission}" do
        title = "test_page"
        title2 = "test_page2"
        hfs = false
        edit_roles = "public"
        validations = ["teachers", "teachers,students", "teachers,students,public"]

        p = create_wiki_page(title, hfs, edit_roles)
        get "/courses/#{@course.id}/wiki/#{p.title}"

        keep_trying_until { f("#wiki_page_new").should be_displayed }

        f('#wiki_page_new .new').click
        f('#wiki_page_title').send_keys(title2)
        submit_form("#add_wiki_page_form")

        keep_trying_until { f("#wiki_page_editing_roles").should be_displayed }

        click_option("#wiki_page_editing_roles", permission)
        #form id is set like this because the id iterator is in the form but im not sure how to grab it directly before committed to the DB with the save
        submit_form("#edit_wiki_page_#{p.id + 1}")

        @course.wiki.wiki_pages.last.editing_roles.should == validations[i]
      end
    end

    it "should take user to page history" do
      title = "test_page"
      hfs = false
      edit_roles = "public"

      p = create_wiki_page(title, hfs, edit_roles)
      #sets body
      p.update_attributes(:body => "test")

      get "/courses/#{@course.id}/wiki/#{p.title}"

      keep_trying_until { f("#page_history").should be_displayed }
      f('#page_history').click

      ff('a[title]').length.should == 3
    end


    it "should load the previous version of the page and roll-back page" do
      title = "test_page"
      hfs = false
      edit_roles = "public"
      body = "test"

      p = create_wiki_page(title, hfs, edit_roles)
      #sets body and then resets it for history verification
      p.update_attributes(:body => body)
      p.update_attributes(:body => "sample")

      get "/courses/#{@course.id}/wiki/#{p.title}"
      keep_trying_until { f("#page_history").should be_displayed }

      f('#page_history').click
      ff('a[title]')[1].click

      f('#wiki_body').text.should == body

      submit_form(".edit_version")
      wait_for_ajax_requests

      assert_flash_notice_message /successfully rolled-back/
      f('#wiki_body').text.should == body
    end

    it "should restore the latest version of the page" do
      title = "test_page"
      hfs = false
      edit_roles = "public"

      p = create_wiki_page(title, hfs, edit_roles)
      #sets body and then resets it for history verification
      p.update_attributes(:body => "test")
      p.update_attributes(:body => "sample")

      old_version = p.versions[2].id

      get "/courses/#{@course.id}/wiki/#{p.title}/revisions/#{old_version}"
      keep_trying_until { f('.forward').should be_displayed }

      #button to restore to most recent version
      f('.forward').click
      wait_for_ajax_requests

      f('#wiki_body').text.should == "sample"
    end

    it "should take user back to revision history" do
      title = "test_page"
      hfs = false
      edit_roles = "public"

      p = create_wiki_page(title, hfs, edit_roles)
      #sets body and then resets it for history verification
      p.update_attributes(:body => "test")
      version = p.versions[1].id

      get "/courses/#{@course.id}/wiki/#{p.title}/revisions/#{version}"
      keep_trying_until { f('.history').should be_displayed }

      f('.history').click
      wait_for_ajax_requests

      ff('a[title]').length.should == 3
    end
  end

  context "as a student" do

    before(:each) do
      course_with_student_logged_in
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
      get "/courses/#{@course.id}/wiki/#{title}"
      wait_for_ajax_requests

      f('.ui-state-error').should include_text(expected_error)
    end

    it "should not allow students to edit if marked for only teachers can edit" do
      #vars for the create_wiki_page method which seeds the used page
      title = "test_page"
      hfs = false
      edit_roles = "teachers"

      create_wiki_page(title, hfs, edit_roles)
      get "/courses/#{@course.id}/wiki/#{title}"
      wait_for_ajax_requests

      f('.edit_link').should be_nil
    end

    it "should allow students to edit wiki if any option but teachers is selected" do
      title = "test_page"
      hfs = false
      edit_roles = "public"

      create_wiki_page(title, hfs, edit_roles)

      get "/courses/#{@course.id}/wiki/#{title}"
      wait_for_ajax_requests

      f('.edit_link').should be_displayed

      #vars for 2nd wiki page with different permissions
      title2 = "test_page2"
      edit_roles2 = "members"

      create_wiki_page(title2, hfs, edit_roles2)

      get "/courses/#{@course.id}/wiki/#{title2}"
      wait_for_ajax_requests

      f('.edit_link').should be_displayed
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
      p.messages_sent.should_not be_nil
      p.messages_sent.should_not be_empty
      p.messages_sent["Updated Wiki Page"].should_not be_nil
      p.messages_sent["Updated Wiki Page"].should_not be_empty
      p.messages_sent["Updated Wiki Page"].map(&:user).should be_include(@user)
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
      p.messages_sent.should be_empty
    end
  end
end
