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
      expect(f("#help-dialog-options")).to be_displayed
    end

    it "should no longer show a browser warning for IE" do
      Setting.set('show_feedback_link', 'true')
      destroy_session(true)
      get("/login")
      driver.execute_script("window.INST.browser = {ie: true, version: 8}")
      f('#footer .help_dialog_trigger').click
      wait_for_ajaximations
      expect(flash_message_present?(:error)).to be_falsey
    end
  end

  context "help as a student" do
    before (:each) do
      course_with_student_logged_in(:active_all => true)
    end

    it "should show the Help dialog when help is clicked and feedback is enabled" do
      get "/dashboard"
      expect(element_exists("#help-dialog")).to be_falsey
      expect(ff('.help_dialog_trigger').length).to eq 0

      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      expect(ff('.help_dialog_trigger').length).to eq 2
      expect(element_exists("#help-dialog")).to be_falsey
      f('.help_dialog_trigger').click
      wait_for_ajaximations
      expect(f("#help-dialog")).to be_displayed
      expect(f("#help-dialog a[href='#teacher_feedback']")).to be_displayed

      support_url = 'http://example.com/support'
      Account.default.update_attribute(:settings, {:support_url => support_url})
      get "/dashboard"
      expect(driver.execute_script("return $('.help_dialog_trigger').attr('href')")).to eq support_url

    end

    it "should show the help link in footer correctly" do
      # if @domain_root_account or Account.default have settings[:support_url] set there should be a link to that site
      support_url = 'http://example.com/support'
      Account.default.update_attribute(:settings, {:support_url => support_url})
      get "/dashboard"
      link = f('.support_url')
      expect(link['href']).to eq support_url
      expect(link['class']).not_to match 'help_dialog_trigger'

      # if show_feedback_link is true hijack clicks on the footer help link to show help dialog
      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      f("#footer-links a[href='#{support_url}']").click
      wait_for_ajaximations
      expect(f("#help-dialog")).to be_displayed
    end

    it "should allow sending the teacher a message" do
      Setting.set('show_feedback_link', 'true')
      get "/courses/#{@course.id}"
      expect(element_exists("#help-dialog")).to be_falsey
      trigger = f('.help_dialog_trigger')
      expect(trigger).to be_displayed
      trigger.click
      wait_for_ajaximations
      expect(f("#help-dialog")).to be_displayed
      teacher_feedback_link = f("#help-dialog a[href='#teacher_feedback']")
      expect(teacher_feedback_link).to be_displayed
      teacher_feedback_link.click
      feedback_form = f("#help-dialog #teacher_feedback")
      expect(feedback_form.find_element(:css, '[name="recipients[]"]')['value']).to eq "course_#{@course.id}_admins"
      feedback_form.find_element(:css, '[name="body"]').send_keys('test message')
      submit_form(feedback_form)
      wait_for_ajaximations
      expect(feedback_form).not_to be_displayed
      cm = ConversationMessage.last
      expect(cm.recipients).to eq @course.instructors
      expect(cm.body).to match(/test message/)
    end

    it "should allow submitting a ticket" do
      skip('193')
      Setting.set('show_feedback_link', 'true')
      get "/dashboard"
      f('.help_dialog_trigger').click
      wait_for_ajaximations
      create_ticket_link = f("#help-dialog a[href='#create_ticket']")
      expect(create_ticket_link).to be_displayed
      create_ticket_link.click
      create_ticket_form = f("#help-dialog #create_ticket")
      create_ticket_form.find_element(:css, 'input[name="error[subject]"]').send_keys('test subject')
      create_ticket_form.find_element(:css, 'textarea[name="error[comments]"]').send_keys('test comments')
      severity = 'blocks_what_i_need_to_do'
      set_value(create_ticket_form.find_element(:css, '[name="error[user_perceived_severity]"]'), severity)
      submit_form(create_ticket_form)
      wait_for_ajaximations
      expect(create_ticket_form).not_to be_displayed
      er = ErrorReport.last
      expect(er.subject).to eq 'test subject'
      expect(er.comments).to eq 'test comments'
      expect(er.data['user_perceived_severity']).to eq severity
      expect(er.guess_email).to eq @user.email
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
      expect(f("#help-dialog")).to be_displayed
      expect(element_exists("#help-dialog a[href='#teacher_feedback']")).to be_falsey
    end

    it "should show the Help dialog on the speedGrader when help is clicked and feedback is enabled" do
      @course.enroll_student(User.create).accept!
      @assignment = @course.assignments.create

      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations
      expect(ff('.help_dialog_trigger').length).to eq 0

      Setting.set('show_feedback_link', 'true')
      get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      wait_for_ajaximations
      trigger = f('#gradebook_header .help_dialog_trigger')
      make_full_screen
      trigger.location_once_scrolled_into_view
      expect(trigger).to be_displayed
      trigger.click
      wait_for_ajaximations
      expect(f("#help-dialog")).to be_displayed
      expect(f("#help-dialog a[href='#create_ticket']")).to be_displayed
    end
  end
end
