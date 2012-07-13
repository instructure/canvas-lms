require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

EDIT_NAME = 'edited appointment'
EDIT_LOCATION = 'edited location'

describe "scheduler" do
  it_should_behave_like "calendar2 selenium tests"

  def fill_out_appointment_group_form(new_appointment_text, opts = {})
    f('.create_link').click
    edit_form = f('#edit_appointment_form')
    keep_trying_until { edit_form.should be_displayed }
    replace_content(fj('input[name="title"]'), new_appointment_text)
    f('.ag_contexts_selector').click
    f('.ag_sections_toggle').click
    if opts[:section_codes]
      opts[:section_codes].each { |code| f("[name='sections[]'][value='#{code}']").click }
    else
      f('[name="context_codes[]"]').click
    end
    f('.ag_contexts_done').click
    date_field = edit_form.find_element(:css, '.date_field')
    date_field.click
    wait_for_animations
    fj('.ui-datepicker-trigger:visible').click
    datepicker_next
    replace_content(edit_form.find_element(:css, '.start_time'), '1')
    replace_content(edit_form.find_element(:css, '.end_time'), '3')
  end

  def submit_appointment_group_form(publish = true)
    save, save_and_publish = ff('.ui-dialog-buttonset .ui-button')
    if publish
      save_and_publish.click
    else
      save.click
    end
    wait_for_ajaximations
  end

  def create_appointment_group_manual(opts = {})
    opts = {
        :publish => true,
        :new_appointment_text => 'new appointment group'
    }.with_indifferent_access.merge(opts)

    expect {
      fill_out_appointment_group_form(opts[:new_appointment_text], opts)
      submit_appointment_group_form(opts[:publish])
      f('.view_calendar_link').text.should == opts[:new_appointment_text]
    }.to change(AppointmentGroup, :count).by(1)
  end

  def click_scheduler_link
    header_buttons = ff('.ui-buttonset > label')
    header_buttons[2].click
    wait_for_ajaximations
  end

  def click_appointment_link
    f('.view_calendar_link').click
    f('.scheduler-mode').should be_displayed
  end

  def click_al_option(option_selector, offset=0)
    ffj('.al-trigger')[offset].click
    options = ffj('.al-options')[offset]
    options.should be_displayed
    options.find_element(:css, option_selector).click
  end

  def delete_appointment_group
    delete_button = fj('.ui-dialog-buttonset .ui-button:contains("Delete")')
    delete_button.click
    wait_for_ajaximations
  end

  def edit_appointment_group(appointment_name = EDIT_NAME, location_name = EDIT_LOCATION)
    f('#edit_appointment_form').should be_displayed
    replace_content(fj('input[name="title"]'), appointment_name)
    replace_content(fj('input[name="location"]'), location_name)
    f('.ui-dialog-buttonset .ui-button').click
    wait_for_ajaximations
    f('.view_calendar_link').text.should == appointment_name
    f('.ag-location').should include_text(location_name)
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

    it "should split time slots" do
      start_time_text = '01'
      end_time_text = '05'
      get "/calendar2"
      click_scheduler_link

      f('.create_link').click
      fj('.ui-datepicker-trigger:visible').click
      datepicker_next
      set_value(f('.start_time'), start_time_text)
      end_time = f('.end_time')
      set_value(end_time, end_time_text)
      end_time.send_keys(:tab)
      f('.splitter a').click
      start_fields = ff('.time-block-list .start_time')
      times = %W(1:00 1:30 2:00 2:30 3:00 3:30 4:00 4:30)
      start_fields.each_with_index do |start_field, i|
        start_field.attribute(:value).should == times[i] + "PM" unless i == 8
      end
      f('.ag_contexts_selector').click
      f("#option_course_#{@course.id}").click
      f('.ag_contexts_done').click
      submit_appointment_group_form
      last_group = AppointmentGroup.last
      last_group.start_at.strftime("%I").should == start_time_text
      last_group.end_at.strftime("%I").should == end_time_text
    end

    it "should create appointment group and go back and publish it" do
      get "/calendar2"
      click_scheduler_link

      create_appointment_group_manual(:publish => false)
      new_appointment_group = AppointmentGroup.last
      new_appointment_group.workflow_state.should == 'pending'
      f('.ag-x-of-x-signed-up').should include_text('unpublished')
      driver.action.move_to(f('.appointment-group-item')).perform
      click_al_option('.edit_link')
      edit_form = f('#edit_appointment_form')
      keep_trying_until { edit_form.should be_displayed }
      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajaximations
      new_appointment_group.reload
      new_appointment_group.workflow_state.should == 'active'
    end

    it "should delete an appointment group" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link

      appointment_group = f('.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.delete_link')
      delete_appointment_group
      f('.list-wrapper').should include_text('You have not created any appointment groups')
    end

    it "should edit an appointment group" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link

      appointment_group = f('.appointment-group-item')
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

    it "should select the correct course sections when editing an appointment group" do
      section = @course.course_sections.create! :name => 'section1'
      @course.course_sections.create! :name => 'section2'
      get "/calendar2"
      click_scheduler_link
      # first create the group
      create_appointment_group_manual :section_codes => %W(course_section_#{section.id})
      # then open it's edit dialog
      appointment_group = f('.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.edit_link')
      # expect only section1 to be selected
      f('.ag_contexts_selector').click
      ffj('.ag_sections input:checked').size.should == 1
    end

    it "should delete an appointment group after clicking appointment group link" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link

      click_al_option('.delete_link')
      delete_appointment_group
      f('.list-wrapper').should include_text('You have not created any appointment groups')
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

      appointment_groups = ffj('.appointment-group-item')
      appointment_groups.each_with_index do |ag, i|
        driver.execute_script("$('.appointment-group-item:index(#{i}').addClass('ui-state-hover')")
        %w(all registered unregistered).each do |registration_status|
          click_al_option('.message_link', i)
          form = keep_trying_until { fj('.ui-dialog:visible') }
          wait_for_ajaximations

          set_value form.find_element(:css, 'select'), registration_status
          wait_for_ajaximations

          form.find_elements(:css, 'li input').should_not be_empty
          set_value form.find_element(:css, 'textarea'), 'hello'
          submit_dialog(form, '.ui-button')

          assert_flash_notice_message /Messages Sent/
          keep_trying_until { fj('.ui-dialog:visible').should be_nil }
        end
      end

      student1.conversations.first.messages.size.should eql 6 # registered/all * 3
      student2.conversations.first.messages.size.should eql 6 # unregistered/all * 2 + registered/all (ug1)
      student3.conversations.first.messages.size.should eql 6 # unregistered/all * 3
      student4.conversations.first.messages.size.should eql 4 # unregistered/all * 2 (not in any group)
      student5.conversations.first.messages.size.should eql 2 # unregistered/all * 1 (doesn't meet any sub_context criteria)
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
      calendar_event = f('.fc-event-bg')
      calendar_event.click
      popup = f('.event-details')
      popup.find_element(:css, '.delete_event_link').click
      delete_appointment_group
      keep_trying_until { element_exists('.fc-event-bg').should be_false }
    end

    it "should allow limiting the max appointments per participant" do
      get "/calendar2"
      click_scheduler_link
      fill_out_appointment_group_form('max appointments')

      # invalid max_appointments
      max_appointments_input = f('[name="max_appointments_per_participant"]')
      replace_content(max_appointments_input, '0')
      submit_appointment_group_form
      ffj('.errorBox[id!="error_box_template"]').size.should eql 1

      replace_content(max_appointments_input, 3)
      expect {
        submit_appointment_group_form
      }.to change(AppointmentGroup, :count).by 1

      ag_id = f('#appointment-group-list li:last-child')['data-appointment-group-id']
      AppointmentGroup.find(ag_id).max_appointments_per_participant.should == 3
    end

    it "should allow removing individual appointments" do
      # user appointment group
      create_appointment_group
      ag = AppointmentGroup.first
      2.times do
        student_in_course(:course => @course, :active_all => true)
        ag.appointments.first.reserve_for(@user, @user)
      end

      # group appointment group
      gc = @course.group_categories.create!(:name => "Blah Groups")
      title = create_appointment_group :sub_context_codes => [gc.asset_string],
                                       :title => "group ag"
      ag = AppointmentGroup.find_by_title(title)
      2.times do |i|
        student_in_course(:course => @course, :active_all => true)
        group = Group.create! :group_category => gc,
                              :context => @course,
                              :name => "Group ##{i+1}"
        group.users << @user
        group.save!
        ag.appointments.first.reserve_for(group, @user)
      end

      get "/calendar2"
      click_scheduler_link

      2.times do |i|
        f(".appointment-group-item:nth-child(#{i+1}) .view_calendar_link").click
        wait_for_ajax_requests

        fj('.fc-event:visible').click
        ff('#attendees li').size.should eql 2

        # delete the first appointment
        fj('.cancel_appointment_link:visible').click
        fj('button:visible:contains(Delete)').click
        wait_for_ajax_requests
        ff('#attendees li').size.should eql 1

        # make sure the appointment was really deleted
        f('#refresh_calendar_link').click
        wait_for_ajax_requests
        fj('.fc-event-time:visible').click
        ff('#attendees li').size.should eql 1

        f('.single_item_done_button').click
      end
    end

    def open_edit_appointment_slot_dialog
      f('.fc-event').click
      f('.edit_event_link').click
    end

    it "should allow me to override the participant limit on a slot-by-slot basis" do
      create_appointment_group :participants_per_appointment => 2
      get "/calendar2"
      wait_for_ajaximations
      click_scheduler_link
      wait_for_ajaximations
      click_appointment_link

      open_edit_event_dialog
      replace_content f('[name=max_participants]'), "5"
      fj('.ui-button:contains(Update)').click
      wait_for_ajaximations

      ag = AppointmentGroup.first
      ag.appointments.first.participants_per_appointment.should eql 5
      ag.participants_per_appointment.should eql 2

      open_edit_event_dialog
      f('[name=max_participants_option]').click
      fj('.ui-button:contains(Update)').click
      wait_for_ajaximations

      ag.reload
      ag.appointments.first.participants_per_appointment.should be_nil
    end

    it "should allow me to create a course with multiple contexts" do
      course1 = @course
      course_with_teacher(:user => @teacher, :active_all => true)
      get "/calendar2"
      click_scheduler_link
      fill_out_appointment_group_form('multiple contexts')
      f('.ag_contexts_selector').click
      ff('.ag_sections_toggle').last.click
      course_box = f("[value=#{@course.asset_string}]")
      course_box.click

      # sections should get checked by their parent
      section_box = f("[value=#{@course.course_sections.first.asset_string}]")
      section_box[:checked].should be_true

      # unchecking all sections should uncheck their parent
      section_box.click
      course_box[:checked].should be_false

      # checking all sections should check parent
      section_box.click
      course_box[:checked].should be_true

      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajaximations
      ag = AppointmentGroup.first
      ag.contexts.should include course1
      ag.contexts.should include @course
      ag.sub_contexts.should eql []
    end

  end

  context "as a student" do

    before (:each) do
      course_with_student_logged_in
    end

    def reserve_appointment_manual(n)
      ff('.fc-event')[n].click
      f('.event-details .reserve_event_link').click
      wait_for_ajax_requests
    end

    it "should let me reserve appointment groups for contexts I am in" do
      my_course = @course
      course_with_student(:active_all => true)
      other_course = @course

      create_appointment_group(:contexts => [other_course, my_course])

      get "/calendar2"
      click_scheduler_link
      wait_for_ajaximations
      click_appointment_link

      reserve_appointment_manual(0)
      f('.fc-event').should include_text "Reserved"
    end

    it "should allow me to cancel existing reservation and sign up for the appointment group from the calendar" do
      tomorrow = (Date.today + 1).to_s
      create_appointment_group(:max_appointments_per_participant => 1,
                               :new_appointments => [
                                   [tomorrow + ' 12:00:00', current_date = tomorrow + ' 13:00:00'],
                                   [tomorrow + ' 14:00:00', current_date = tomorrow + ' 15:00:00'],
                               ])
      get "/calendar2"
      wait_for_ajaximations
      click_scheduler_link
      click_appointment_link

      reserve_appointment_manual(0)
      f('.fc-event').should include_text "Reserved"

      # try to reserve the second appointment
      reserve_appointment_manual(1)
      fj('.ui-button:contains(Reschedule)').click
      wait_for_ajax_requests

      event1, event2 = ff('.fc-event')
      event1.should include_text "Available"
      event2.should include_text "Reserved"
    end

    it "should not let me book too many appointments" do
      tomorrow = (Date.today + 1).to_s
      create_appointment_group(:max_appointments_per_participant => 2,
                               :new_appointments => [
                                   [tomorrow + ' 12:00:00', current_date = tomorrow + ' 13:00:00'],
                                   [tomorrow + ' 14:00:00', current_date = tomorrow + ' 15:00:00'],
                                   [tomorrow + ' 16:00:00', current_date = tomorrow + ' 17:00:00'],
                               ])
      get "/calendar2"
      wait_for_ajaximations
      click_scheduler_link
      click_appointment_link

      reserve_appointment_manual(0)
      reserve_appointment_manual(1)
      e1, e2, *rest = ff('.fc-event')
      e1.should include_text "Reserved"
      e2.should include_text "Reserved"

      reserve_appointment_manual(2)
      fj('.ui-button:contains("OK")').click # "can't reserve" dialog
      f('.fc-event:nth-child(3)').should include_text "Available"
    end

    it "should not allow me to cancel reservations from the attendees list" do
      create_appointment_group
      ag = AppointmentGroup.first
      ag.appointments.first.reserve_for(@user, @user)
      get "/calendar2"
      wait_for_ajaximations
      click_scheduler_link
      wait_for_ajaximations
      click_appointment_link

      fj('.fc-event:visible').click
      ff('#reservations').size.should be_zero
    end

  end

end
