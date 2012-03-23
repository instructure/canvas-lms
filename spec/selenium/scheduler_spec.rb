require File.expand_path(File.dirname(__FILE__) + '/common')

EDIT_NAME = 'edited appointment'
EDIT_LOCATION = 'edited location'

describe "scheduler" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    Account.default.tap { |a| a.settings[:enable_scheduler] = true; a.save }
  end

  def create_appointment_group_manual(should_publish = true)
    new_appointment_text = 'new appointment group'
    expect {
      driver.find_element(:css, '.create_link').click
      edit_form = driver.find_element(:id, 'edit_appointment_form')
      keep_trying_until { edit_form.should be_displayed }
      replace_content(find_with_jquery('input[name="title"]'), new_appointment_text)
      date_field = edit_form.find_element(:css, '.date_field')
      date_field.click
      wait_for_animations
      find_with_jquery('.ui-datepicker-trigger:visible').click
      datepicker_next
      replace_content(edit_form.find_element(:css, '.start_time'), '1')
      replace_content(edit_form.find_element(:css, '.end_time'), '3')
      save_buttons = ff(".ui-dialog-buttonset .ui-button")
      if should_publish
        save_buttons[0].click
      else
        save_buttons[1].click
      end
      wait_for_ajaximations
      driver.find_element(:css, '.view_calendar_link').text.should == new_appointment_text
    }.to change(AppointmentGroup, :count).by(1)
  end

  def click_scheduler_link
    header_buttons = driver.find_elements(:css, '.ui-buttonset > label')
    header_buttons[2].click
    wait_for_ajaximations
  end

  def click_appointment_link
    driver.find_element(:css, '.view_calendar_link').click
    driver.find_element(:css, '.scheduler-mode').should be_displayed
  end

  def click_al_option(option_selector, offset=0)
    find_all_with_jquery('.al-trigger')[offset].click
    options = find_all_with_jquery('.al-options')[offset]
    options.should be_displayed
    options.find_element(:css, option_selector).click
  end

  def delete_appointment_group
    delete_button = find_with_jquery('.ui-dialog-buttonset .ui-button:contains("Delete")')
    delete_button.click
    wait_for_ajaximations
  end

  def edit_appointment_group(appointment_name = EDIT_NAME, location_name = EDIT_LOCATION)
    driver.find_element(:id, 'edit_appointment_form').should be_displayed
    replace_content(find_with_jquery('input[name="title"]'), appointment_name)
    replace_content(find_with_jquery('input[name="location"]'), location_name)
    driver.find_element(:css, '.ui-dialog-buttonset .ui-button').click
    wait_for_ajaximations
    driver.find_element(:css, '.view_calendar_link').text.should == appointment_name
    driver.find_element(:css, '.ag-location').should include_text(location_name)
  end

  def create_appointment_group(params={})
    current_date = Date.today.to_s
    default_params = {
        :title => "new appointment group",
        :context => @course,
        :new_appointments => [
            [current_date + ' 12:00:00', current_date + ' 13:00:00'],
        ]
    }
    ag = @course.appointment_groups.create(default_params.merge(params))
    ag.publish!
    ag.title
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should create a new appointment group" do
      get "/calendar2"
      click_scheduler_link

      create_appointment_group_manual
    end

    it "should create appointment group and go back and publish it" do
      get "/calendar2"
      click_scheduler_link

      create_appointment_group_manual(false)
      new_appointment_group = AppointmentGroup.last
      new_appointment_group.workflow_state.should == 'pending'
      f('.ag-x-of-x-signed-up').should include_text('unpublished')
      driver.action.move_to(f('.appointment-group-item')).perform
      click_al_option('.edit_link')
      edit_form = driver.find_element(:id, 'edit_appointment_form')
      keep_trying_until { edit_form.should be_displayed }
      driver.find_element(:css, '.ui-dialog-buttonset .ui-button-primary').click
      wait_for_ajaximations
      new_appointment_group.reload
      new_appointment_group.workflow_state.should == 'active'
    end

    it "should delete an appointment group" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link

      appointment_group = driver.find_element(:css, '.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.delete_link')
      delete_appointment_group
      driver.find_element(:css, '.list-wrapper').should include_text('You have not created any appointment groups')
    end

    it "should edit an appointment group" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link

      appointment_group = driver.find_element(:css, '.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.edit_link')
      edit_appointment_group
    end

    it "should edit an appointment group after clicking appointment group link" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      click_al_option('.edit_link')
      edit_appointment_group
    end

    it "should delete an appointment group after clicking appointment group link" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link

      click_al_option('.delete_link')
      delete_appointment_group
      driver.find_element(:css, '.list-wrapper').should include_text('You have not created any appointment groups')
    end

    it "should send messages to appropriate participants" do
      gc = @course.group_categories.create!
      ug1 = @course.groups.create!(:group_category => gc)
      ug1.users << student1 = student_in_course(:course => @course, :active_all => true).user
      ug1.users << student2 = student_in_course(:course => @course, :active_all => true).user

      ug2 = @course.groups.create!(:group_category => gc)
      ug2.users << student3 = student_in_course(:course => @course, :active_all => true).user

      student4 = student_in_course(:course => @course, :active_all => true).user

      other_section = @course.course_sections.create!
      @course.enroll_user(student5 = user(:active_all => true), 'StudentEnrollment', :section => other_section).accept!

      # create some appointment groups and sign up a participant in each one
      appointment_participant_model(:course => @course, :participant => student1)
      appointment_participant_model(:course => @course, :participant => ug1)
      appointment_participant_model(:course => @course, :sub_context => @course.default_section, :participant => student1)

      get "/calendar2"
      click_scheduler_link

      appointment_groups = find_all_with_jquery('.appointment-group-item')
      appointment_groups.each_with_index do |ag, i|
        driver.execute_script("$('.appointment-group-item:index(#{i}').addClass('ui-state-hover')")
        ["all", "registered", "unregistered"].each do |registration_status|
          click_al_option('.message_link', i)
          form = keep_trying_until { find_with_jquery('.ui-dialog form:visible') }
          wait_for_ajaximations

          set_value form.find_element(:css, 'select'), registration_status
          wait_for_ajaximations

          form.find_elements(:css, 'li input').should_not be_empty
          set_value form.find_element(:css, 'textarea'), 'hello'
          form.submit

          assert_flash_notice_message /Messages Sent/
          keep_trying_until { find_with_jquery('.ui-dialog:visible').should be_nil }
        end
      end

      student1.conversations.first.messages.size.should eql 6 # registered/all * 3
      student2.conversations.first.messages.size.should eql 6 # unregistered/all * 2 + registered/all (ug1)
      student3.conversations.first.messages.size.should eql 6 # unregistered/all * 3
      student4.conversations.first.messages.size.should eql 4 # unregistered/all * 2 (not in any group)
      student5.conversations.first.messages.size.should eql 4 # unregistered/all * 2 (not in default section)
    end

    it "should validate the appointment group shows up on the calendar" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      element_exists('.fc-event-bg').should be_true
    end

    it "should delete the appointment group from the calendar" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      calendar_event = driver.find_element(:css, '.fc-event-bg')
      calendar_event.click
      popup = driver.find_element(:css, '.event-details')
      popup.find_element(:css, '.delete_event_link').click
      delete_appointment_group
      keep_trying_until { element_exists('.fc-event-bg').should be_false }
    end


  end

  context "as a student" do

    before (:each) {course_with_student_logged_in}

    it "should allow me to cancel existing reservation and sign up for the appointment group from the calendar" do
      create_appointment_group(:max_appointments_per_participant => 1,
                               :new_appointments => [
                                   [Date.today.to_s + ' 12:00:00', current_date = Date.today.to_s + ' 13:00:00'],
                                   [Date.today.to_s + ' 14:00:00', current_date = Date.today.to_s + ' 15:00:00'],
                               ])
      get "/calendar2"
      wait_for_ajaximations
      click_scheduler_link
      click_appointment_link

      # click the first calendar event to open it's popover
      driver.find_elements(:css, '.fc-event')[0].click
      driver.find_element(:css, '.event-details .reserve_event_link').click
      wait_for_ajax_requests
      driver.find_element(:css, '.fc-event').should include_text "Reserved"

      # now try to reserve the second appointment
      driver.find_elements(:css, '.fc-event')[1].click
      driver.find_element(:css, '.event-details .reserve_event_link').click
      wait_for_ajax_requests
      find_with_jquery('.ui-button:contains(Reschedule)').click
      wait_for_ajax_requests

      event1, event2 = driver.find_elements(:css, '.fc-event')
      event1.should include_text "Available"
      event2.should include_text "Reserved"
    end

  end

end
