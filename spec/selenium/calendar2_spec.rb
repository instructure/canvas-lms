require File.expand_path(File.dirname(__FILE__) + '/common')

describe "calendar2" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    Account.default.tap { |a| a.settings[:enable_scheduler] = true; a.save }
    course_with_teacher_logged_in
  end

  def make_event(params = {})
    opts = {
        :context => @user,
        :start => Time.now,
        :description => "Test event"
    }.with_indifferent_access.merge(params)
    c = CalendarEvent.new :description => opts[:description],
                          :start_at => opts[:start]
    c.context = opts[:context]
    c.save!
    c
  end

  def create_assignment_event(assignment_title)
    edit_event_dialog = driver.find_element(:id, 'edit_event_tabs')
    edit_event_dialog.should be_displayed
    edit_event_dialog.find_element(:css, '.edit_assignment_option').click
    edit_assignment_form = edit_event_dialog.find_element(:id, 'edit_assignment_form')
    title = edit_assignment_form.find_element(:id, 'assignment_title')
    replace_content(title, assignment_title)
    find_with_jquery('.ui-datepicker-trigger:visible').click
    datepicker_next
    edit_assignment_form.submit
    wait_for_ajax_requests
    driver.find_element(:css, '.fc-button-next').click
    find_with_jquery('.fc-day-number:contains(15)').click
    keep_trying_until { driver.find_element(:css, '.fc-view-month .fc-event-title').should include_text(assignment_title) }
  end

  def create_calendar_event(event_title)
    edit_event_dialog = driver.find_element(:id, 'edit_event_tabs')
    edit_event_dialog.should be_displayed
    edit_event_form = edit_event_dialog.find_element(:id, 'edit_calendar_event_form')
    title = edit_event_form.find_element(:id, 'calendar_event_title')
    replace_content(title, event_title)
    find_with_jquery('.ui-datepicker-trigger:visible').click
    datepicker_next
    edit_event_form.submit
    wait_for_ajax_requests
    driver.find_element(:css, '.fc-button-next').click
    find_with_jquery('.fc-day-number:contains(15)').click
    keep_trying_until { driver.find_element(:css, '.fc-view-month .fc-event-title').should include_text(event_title) }
  end

  describe "sidebar" do

    describe "mini calendar" do

      it "should add the event class to days with events" do
        c = make_event
        get "/calendar2"
        wait_for_ajax_requests

        events = driver.find_elements(:css, "#minical .event")
        events.size.should == 1
        events.first.text.strip.should == c.start_at.day.to_s
      end

      it "should change the main calendar's month on click" do
        title_selector = "#calendar-app .fc-header-title"
        get "/calendar2"

        orig_title = driver.find_element(:css, title_selector).text
        driver.find_element(:css, "#minical .fc-other-month").click

        orig_title.should_not == driver.find_element(:css, title_selector)
      end
    end

    describe "contexts list" do
      it "should have a menu for adding stuff" do
        get "/calendar2"

        contexts = driver.find_elements(:css, "#context-list > li")

        # first context is the user
        actions = contexts[0].find_elements(:css, "li > a")
        actions.size.should == 1
        actions.first["data-action"].should == "add_event"

        # course context
        actions = contexts[1].find_elements(:css, "li > a")
        actions.size.should == 2
        actions.first["data-action"].should == "add_event"
        actions.second["data-action"].should == "add_assignment"
      end

      it "should create an event through the context list drop down" do
        #Bug - 7111
        pending("Course in context list being disabled bug")
        event_title = 'new event'
        get "/calendar2"
        wait_for_ajaximations

        driver.execute_script(%{$(".context_list_context:nth-child(2)").trigger('mouseenter')})
        find_with_jquery('ul#context-list li:nth-child(2) button').click
        driver.find_element(:id, "ui-menu-1-0").click
        edit_event_dialog = driver.find_element(:id, 'edit_event_tabs')
        edit_event_dialog.should be_displayed
        create_calendar_event(event_title)
      end

      it "should create an assignment through the context list drop down" do
        #Bug - 7111
        pending("Course in context list being disabled bug")
        assignment_title = 'new assignment'
        get "/calendar2"
        wait_for_ajaximations

        driver.execute_script(%{$(".context_list_context:nth-child(2)").trigger('mouseenter')})
        find_with_jquery('ul#context-list li:nth-child(2) button').click
        driver.find_element(:id, "ui-menu-1-1").click
        edit_event_dialog = driver.find_element(:id, 'edit_event_tabs')
        edit_event_dialog.should be_displayed
        create_assignment_event(assignment_title)
      end

      it "should toggle event display when context is clicked" do
        make_event :context => @course, :start => Time.now
        get "/calendar2"

        driver.find_element(:css, '.context_list_context').click
        context_course_item = find_with_jquery('.context_list_context:nth-child(2)')
        context_course_item.should have_class('checked')
        driver.find_element(:css, '.fc-event').should be_displayed

        context_course_item.click
        context_course_item.should have_class('not-checked')
        element_exists(:css, '.fc_event').should be_false
      end

      it "should validate calendar feed display" do
        get "/calendar2"

        driver.find_element(:link, 'Calendar Feed').click
        driver.find_element(:id, 'calendar_feed_box').should be_displayed
      end
    end

    describe "undated calendar items" do
      it "should show undated events after clicking link" do
        e = make_event :start => nil, :title => "pizza party"
        get "/calendar2"

        driver.find_element(:css, ".undated-events-link").click
        wait_for_ajaximations
        undated_events = driver.find_elements(:css, "#undated-events > ul > li")
        undated_events.size.should == 1
        undated_events.first.text.should =~ /#{e.title}/
      end
    end
  end

  describe "main calendar" do

    before (:each) do
      get "/calendar2"
    end

    def change_calendar(css_selector = '.fc-button-next')
      driver.find_element(:css, '.calendar .fc-header-left ' + css_selector).click
      wait_for_ajax_requests
    end

    def get_header_text
      header = driver.find_element(:css, '.calendar .fc-header .fc-header-title')
      header.text
    end

    it "should create an event through clicking on a calendar day" do
      driver.find_element(:css, '.calendar .fc-today').click
      create_calendar_event('new event')
    end

    it "should create an assignment by clicking on a calendar day" do
      driver.find_element(:css, '.calendar .fc-today').click
      create_assignment_event('new assignment')
    end

    it "more options link should go to calendar_event edit page" do
      driver.find_element(:css, '.calendar .fc-today').click
      create_calendar_event('new event')

      driver.find_element(:css, '.fc-event').click
      find_with_jquery('.popover-links-holder:visible').should_not be_nil
      driver.find_element(:css, '.popover-links-holder .edit_event_link').click
      link = driver.find_element(:css, '#edit_calendar_event_form .more_options_link')
      link["href"].should =~ %r{calendar_events/\d+/edit$}
    end

    it "editing an existing assignment should select the correct assignment group" do
      group1 = @course.assignment_groups.create!(:name => "Assignment Group 1")
      group2 = @course.assignment_groups.create!(:name => "Assignment Group 2")
      assignment1 = @course.active_assignments.create(:name => "Assignment 1", :assignment_group => group1, :due_at => Time.zone.now)
      assignment2 = @course.active_assignments.create(:name => "Assignment 2", :assignment_group => group2, :due_at => Time.zone.now)

      get "/calendar2"

      events = driver.find_elements(:css, '.fc-event')
      event1 = events.detect{ |e| e.text =~ /Assignment 1/ }
      event2 = events.detect{ |e| e.text =~ /Assignment 2/ }
      event1.should_not be_nil
      event2.should_not be_nil
      event1.should_not == event2

      event1.click
      driver.find_element(:css, '.popover-links-holder .edit_event_link').click
      select = driver.find_element(:css, '#edit_assignment_form .assignment_group')
      select = Selenium::WebDriver::Support::Select.new(select)
      select.first_selected_option.attribute(:value).to_i.should == group1.id
      driver.find_element(:css, 'div.ui-dialog a.ui-dialog-titlebar-close').click

      event2.click
      driver.find_element(:css, '.popover-links-holder .edit_event_link').click
      select = driver.find_element(:css, '#edit_assignment_form .assignment_group')
      select = Selenium::WebDriver::Support::Select.new(select)
      select.first_selected_option.attribute(:value).to_i.should == group2.id
      driver.find_element(:css, 'div.ui-dialog #assignment_title').tap { |tf| tf.clear; tf.send_keys("Assignment 2!") }
      driver.find_element(:css, 'div.ui-dialog button[type=submit]').click
      wait_for_ajax_requests
      assignment2.reload.title.should == "Assignment 2!"
      assignment2.assignment_group.should == group2
    end

    it "should change the month" do
      old_header_title = get_header_text
      change_calendar
      old_header_title.should_not == get_header_text
    end

    it "should change the week" do
      header_buttons = driver.find_elements(:css, '.ui-buttonset > label')
      header_buttons[0].click
      wait_for_ajaximations
      old_header_title = get_header_text
      change_calendar('.fc-button-prev')
      old_header_title.should_not == get_header_text
    end

    it "should test the today button" do
      current_month_num = Time.now.month
      current_month = Date::MONTHNAMES[current_month_num]

      change_calendar
      get_header_text.should_not == current_month
      driver.find_element(:css, '.fc-button-today').click
      get_header_text.should == (current_month + ' ' + Time.now.year.to_s)
    end
  end

  describe "scheduler" do

    EDIT_NAME = 'edited appointment'
    EDIT_LOCATION = 'edited location'

    def create_appointment_group_api
      ag = @course.appointment_groups.create(:title => "new appointment group")
      ag.publish!
      ag.title
    end

    def create_appointment_group_manual
      new_appointment_text = 'new appointment group'
      expect {
        driver.find_element(:css, '.create_link').click
        edit_form = driver.find_element(:id, 'edit_appointment_form')
        keep_trying_until { edit_form.should be_displayed }
        replace_content(find_with_jquery('input[name="title"]'), new_appointment_text)
        date_field = edit_form.find_element(:css, '.date_field')
        date_field.click
        find_with_jquery('.ui-datepicker-trigger:visible').click
        datepicker_next
        replace_content(edit_form.find_element(:css, '.start_time'), '1')
        replace_content(edit_form.find_element(:css, '.end_time'), '3')
        driver.find_element(:css, '.ui-dialog-buttonset .ui-button-primary').click
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

    it "should create a new appointment group" do
      get "/calendar2"
      click_scheduler_link

      create_appointment_group_manual
    end

    it "should test bad data errors in date while creating a new appointment group" do
      get "/calendar2"
      click_scheduler_link
      driver.find_element(:css, '.create_link').click
      edit_form = driver.find_element(:id, 'edit_appointment_form')
      start_time = edit_form.find_element(:css, '.start_time')
      end_time = edit_form.find_element(:css, '.end_time')
      title = find_with_jquery('input[name="title"]')
      replace_content(start_time, '11111')
      end_time.click
      title.click
      edit_form.find_element(:css, '.start_time').should have_class('error')
      edit_form.find_element(:css, '.end_time').should have_class('error')
      driver.find_element(:css, '.ui-dialog-buttonset .ui-button-primary').click
      driver.switch_to.alert.dismiss
      edit_form.should be_displayed
    end

    it "should delete an appointment group" do
      create_appointment_group_api
      get "/calendar2"
      click_scheduler_link

      appointment_group = driver.find_element(:css, '.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.delete_link')
      delete_appointment_group
      driver.find_element(:css, '.list-wrapper').should include_text('You have not created any appointment groups')
    end

    it "should edit an appointment group" do
      create_appointment_group_api
      get "/calendar2"
      click_scheduler_link

      appointment_group = driver.find_element(:css, '.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.edit_link')
      edit_appointment_group
    end

    it "should edit an appointment group after clicking appointment group link" do
      create_appointment_group_api
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      click_al_option('.edit_link')
      edit_appointment_group
    end

    it "should delete an appointment group after clicking appointment group link" do
      create_appointment_group_api
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
        driver.action.move_to(ag).perform
        ["all", "registered", "unregistered"].each do |registration_status|
          click_al_option('.message_link', i)
          form = keep_trying_until{ find_with_jquery('.ui-dialog form:visible') }
          wait_for_ajaximations

          set_value form.find_element(:css, 'select'), registration_status
          wait_for_ajaximations

          form.find_elements(:css, 'li input').should_not be_empty
          set_value form.find_element(:css, 'textarea'), 'hello'
          form.submit

          assert_flash_notice_message /Messages Sent/
          keep_trying_until{ !form.displayed? }
        end
      end

      student1.conversations.first.messages.size.should eql 6 # registered/all * 3
      student2.conversations.first.messages.size.should eql 6 # unregistered/all * 2 + registered/all (ug1)
      student3.conversations.first.messages.size.should eql 6 # unregistered/all * 3
      student4.conversations.first.messages.size.should eql 4 # unregistered/all * 2 (not in any group)
      student5.conversations.first.messages.size.should eql 4 # unregistered/all * 2 (not in default section)
    end

    it "should validate the appointment group shows up on the calendar" do
      get "/calendar2"
      click_scheduler_link
      create_appointment_group_manual
      click_appointment_link
      element_exists(:css, '.fc-event-bg').should be_true
    end

    it "should delete the appointment group from the calendar" do
      get "/calendar2"
      click_scheduler_link
      create_appointment_group_manual
      click_appointment_link
      calendar_event = driver.find_element(:css, '.fc-event-bg')
      calendar_event.click
      popup = driver.find_element(:css, '.event-details')
      popup.find_element(:css, '.delete_event_link').click
      delete_appointment_group
      keep_trying_until { element_exists(:css, '.fc-event-bg').should be_false }
    end
  end
end
