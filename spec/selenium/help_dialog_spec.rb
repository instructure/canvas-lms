require File.expand_path(File.dirname(__FILE__) + '/common')

describe "help dialog" do
  include_examples "in-process server selenium tests"

  context "no user logged in" do
    it "should work with no logged in user" do
      Setting.set('show_feedback_link', 'true')
      destroy_session(true)
      get("/login")
      f('#footer .help_dialog_trigger').click
      wait_for_ajaximations
      f("#help-dialog-options").should be_displayed
    end

    it "should no longer show a browser warning for IE" do
      Setting.set('show_feedback_link', 'true')
      destroy_session(true)
      get("/login")
      driver.execute_script("window.INST.browser = {ie: true, version: 8}")
      f('#footer .help_dialog_trigger').click
      wait_for_ajaximations
      flash_message_present?(:error).should be_false
    end
  end

  context "help as a student" do
    before (:each) do
      course_with_student_logged_in(:active_all => true)
    end

    it "should show the Help dialog when help is clicked and feedback is enabled" do
      get "/dashboard"
      element_exists("#help-dialog").should be_false
      ff('.help_dialog_trigger').length.should == 0

      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      ff('.help_dialog_trigger').length.should == 2
      element_exists("#help-dialog").should be_false
      f('.help_dialog_trigger').click
      wait_for_ajaximations
      f("#help-dialog").should be_displayed
      f("#help-dialog a[href='#teacher_feedback']").should be_displayed

      support_url = 'http://example.com/support'
      Account.default.update_attribute(:settings, {:support_url => support_url})
      get "/dashboard"
      driver.execute_script("return $('.help_dialog_trigger').attr('href')").should == support_url

    end

    it "should show the help link in footer correctly" do
      # if @domain_root_account or Account.default have settings[:support_url] set there should be a link to that site
      support_url = 'http://example.com/support'
      Account.default.update_attribute(:settings, {:support_url => support_url})
      get "/dashboard"
      link = f('.support_url')
      link['href'].should == support_url
      link['class'].should_not match 'help_dialog_trigger'

      # if show_feedback_link is true hijack clicks on the footer help link to show help dialog
      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      f("#footer-links a[href='#{support_url}']").click
      wait_for_ajaximations
      f("#help-dialog").should be_displayed
    end

    it "should allow sending the teacher a message" do
      Setting.set('show_feedback_link', 'true')
      get "/courses/#{@course.id}"
      element_exists("#help-dialog").should be_false
      trigger = f('.help_dialog_trigger')
      trigger.should be_displayed
      trigger.click
      wait_for_ajaximations
      f("#help-dialog").should be_displayed
      teacher_feedback_link = f("#help-dialog a[href='#teacher_feedback']")
      teacher_feedback_link.should be_displayed
      teacher_feedback_link.click
      feedback_form = f("#help-dialog #teacher_feedback")
      feedback_form.find_element(:css, '[name="recipients[]"]')['value'].should == "course_#{@course.id}_admins"
      feedback_form.find_element(:css, '[name="body"]').send_keys('test message')
      submit_form(feedback_form)
      wait_for_ajaximations
      feedback_form.should_not be_displayed
      cm = ConversationMessage.last
      cm.recipients.should == @course.instructors
      cm.body.should match(/test message/)
    end

    it "should allow submitting a ticket" do
      pending('193')
      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      f('.help_dialog_trigger').click
      wait_for_ajaximations
      create_ticket_link = f("#help-dialog a[href='#create_ticket']")
      create_ticket_link.should be_displayed
      create_ticket_link.click
      create_ticket_form = f("#help-dialog #create_ticket")
      create_ticket_form.find_element(:css, 'input[name="error[subject]"]').send_keys('test subject')
      create_ticket_form.find_element(:css, 'textarea[name="error[comments]"]').send_keys('test comments')
      severity = 'blocks_what_i_need_to_do'
      set_value(create_ticket_form.find_element(:css, '[name="error[user_perceived_severity]"]'), severity)
      submit_form(create_ticket_form)
      wait_for_ajaximations
      create_ticket_form.should_not be_displayed
      er = ErrorReport.last
      er.subject.should == 'test subject'
      er.comments.should == 'test comments'
      er.data['user_perceived_severity'].should == severity
      er.guess_email.should == @user.email
    end
  end

  context "help dialog as a teacher" do
    before (:each) do
      course_with_teacher_logged_in(:active_all => true)
    end

    it "should not show the Message teacher button if not a student" do
      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      f('.help_dialog_trigger').click
      wait_for_ajaximations
      f("#help-dialog").should be_displayed
      element_exists("#help-dialog a[href='#teacher_feedback']").should be_false
    end

    it "should show the Help dialog on the speedGrader when help is clicked and feedback is enabled" do
      @course.enroll_student(User.create).accept!
      @assignment = @course.assignments.create

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations
      ff('.help_dialog_trigger').length.should == 0

      Setting.set('show_feedback_link', 'true')
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations
      trigger = f('#gradebook_header .help_dialog_trigger')
      make_full_screen
      trigger.location_once_scrolled_into_view
      trigger.should be_displayed
      trigger.click
      wait_for_ajaximations
      f("#help-dialog").should be_displayed
      f("#help-dialog a[href='#create_ticket']").should be_displayed
    end
  end
end
