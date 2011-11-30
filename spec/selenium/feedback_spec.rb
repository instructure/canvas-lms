require File.expand_path(File.dirname(__FILE__) + '/common')

describe "help" do
  it_should_behave_like "in-process server selenium tests"

  it "should show the Help dialog when 'help' is clicked and feedback is enabled" do
    course_with_student_logged_in(:active_all => true)
    
    get "/dashboard"
    driver.find_elements(:css, '#feedback_link').length.should == 0
    
    Setting.set('show_feedback_link', 'true')
    get "/dashboard"
    driver.find_element(:css, '#feedback_link').should be_displayed
    driver.find_element(:css, "#help_dialog").should_not be_displayed
    driver.find_element(:css, '#feedback_link').click
    wait_for_ajaximations
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").should be_displayed
  end
  
  it "should show the Help dialog on the speedgrader when 'help' is clicked and feedback is enabled" do
    course_with_teacher_logged_in(:active_all => true)
    @course.enroll_student(User.create).accept!
    @assignment = @course.assignments.create
    
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    driver.find_elements(:css, '#feedback_link').length.should == 0
    
    Setting.set('show_feedback_link', 'true')
    get "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
    feedback_link = nil
    keep_trying_until {
      feedback_link = driver.find_element(:css, '#feedback_link')
      feedback_link.location_once_scrolled_into_view
      feedback_link.displayed?
    }
    driver.find_element(:css, "#help_dialog").should_not be_displayed
    feedback_link.click
    wait_for_ajaximations
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .file_ticket_link").should be_displayed
  end
  
  it "should allow sending the teacher a message" do
    course_with_student_logged_in(:active_all => true)
    
    Setting.set('show_feedback_link', 'true')
    get "/dashboard"
    driver.find_element(:css, '#feedback_link').should be_displayed
    driver.find_element(:css, "#help_dialog").should_not be_displayed
    driver.find_element(:css, '#feedback_link').click
    wait_for_ajaximations
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback_form_subject').send_keys('test subject') 
    driver.find_element(:css, '#feedback_form_comments').send_keys('test message') 
    driver.find_element(:css, '#feedback_dialog .send_button').click
    keep_trying_until{ !driver.find_element(:css, '#feedback_dialog').displayed? }
    cm = ConversationMessage.last
    cm.body.should match(/test message/)
  end
  
  it "should allow submitting a ticket" do
    course_with_student_logged_in(:active_all => true)
    
    Setting.set('show_feedback_link', 'true')
    get "/dashboard"
    driver.find_element(:css, '#feedback_link').should be_displayed
    driver.find_element(:css, "#help_dialog").should_not be_displayed
    driver.find_element(:css, '#feedback_link').click
    wait_for_ajaximations
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .file_ticket_link").should be_displayed
    driver.find_element(:css, "#help_dialog .file_ticket_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback_form_subject').send_keys('test subject') 
    driver.find_element(:css, '#feedback_form_comments').send_keys('test message') 
    driver.find_element(:css, '#feedback_dialog .send_button').click
    keep_trying_until{ !driver.find_element(:css, '#feedback_dialog').displayed? }
    er = ErrorReport.last
    er.subject.should == 'test subject'
    er.comments.should == 'test message'
  end
  
  it "should not show the 'Message teacher' button if not a student" do
    course_with_teacher_logged_in(:active_all => true)
    
    Setting.set('show_feedback_link', 'true')
    get "/dashboard"
    driver.find_element(:css, '#feedback_link').click
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").should_not be_displayed
  end
  
  it "should load the ticket dialog if button is clicked" do
    course_with_student_logged_in(:active_all => true)
    
    Setting.set('show_feedback_link', 'true')
    get "/dashboard"
    driver.find_element(:css, '#feedback_link').click
    wait_for_ajaximations
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .file_ticket_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback-dialog-settings').should_not be_displayed
    driver.find_element(:css, '#feedback_dialog .feedback_message').should be_displayed
    
    # even if the message teacher dialog has already been loaded
    driver.find_elements(:css, '.ui-dialog-titlebar-close').select(&:displayed?).each(&:click)
    
    driver.find_element(:css, '#feedback_link').click
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback-dialog-settings').should be_displayed
    driver.find_element(:css, '#feedback_dialog .feedback_message').should_not be_displayed
    driver.find_elements(:css, '.ui-dialog-titlebar-close').select(&:displayed?).each(&:click)
    
    driver.find_element(:css, '#feedback_link').click
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .file_ticket_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback-dialog-settings').should_not be_displayed
    driver.find_element(:css, '#feedback_dialog .feedback_message').should be_displayed
  end
  
  it "should load the message teacher dialog if button is clicked" do
    course_with_student_logged_in(:active_all => true)
    
    Setting.set('show_feedback_link', 'true')
    get "/dashboard"
    driver.find_element(:css, '#feedback_link').click
    wait_for_ajaximations
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback-dialog-settings').should be_displayed
    driver.find_element(:css, '#feedback_dialog .feedback_message').should_not be_displayed
    
    # even if the ticket dialog has already been loaded
    driver.find_elements(:css, '.ui-dialog-titlebar-close').select(&:displayed?).each(&:click)
    driver.find_element(:css, '#feedback_link').click
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .file_ticket_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback-dialog-settings').should_not be_displayed
    driver.find_element(:css, '#feedback_dialog .feedback_message').should be_displayed
    
    driver.find_elements(:css, '.ui-dialog-titlebar-close').select(&:displayed?).each(&:click)
    driver.find_element(:css, '#feedback_link').click
    driver.find_element(:css, "#help_dialog").should be_displayed
    driver.find_element(:css, "#help_dialog .message_teacher_link").click
    keep_trying_until{ driver.find_elements(:css, '#feedback_dialog #feedback_form_subject').first.try(:displayed?) }
    driver.find_element(:css, '#feedback-dialog-settings').should be_displayed
    driver.find_element(:css, '#feedback_dialog .feedback_message').should_not be_displayed
    driver.find_elements(:css, '.ui-dialog-titlebar-close').select(&:displayed?).each(&:click)
  end
end
