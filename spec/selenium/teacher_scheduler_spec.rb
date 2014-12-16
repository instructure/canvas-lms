require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/scheduler_common')

describe "scheduler" do
  include_examples "in-process server selenium tests"
  context "as a teacher" do

    before (:once) do
        Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
    end

    before (:each) do
      course_with_teacher_logged_in
      make_full_screen
    end

    it "should split time slots" do
      start_time_text = '02'
      end_time_text = '06'
      local_start_time = '01'
      local_end_time = '05'

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
      times = %W(2:00 2:30 3:00 3:30 4:00 4:30 5:00 5:30)
      start_fields.each_with_index do |start_field, i|
        expect(start_field.attribute(:value).strip).to eq times[i] + "pm" unless i == 8
      end
      f('.ag_contexts_selector').click
      f("#option_course_#{@course.id}").click
      f('.ag_contexts_done').click
      submit_appointment_group_form
      get "/calendar2"
      last_group = AppointmentGroup.last

      start_time_correct = true if last_group.end_at.strftime("%I") == end_time_text || local_end_time
      end_time_correct = true if last_group.start_at.strftime("%I") == start_time_text || local_start_time

      expect(start_time_correct).to eq true
      expect(end_time_correct).to eq true
    end

    it "should allow checkboxes in the options section to be edited" do
      get "/calendar2"
      click_scheduler_link
      create_appointment_group_manual :checkable_options => {
          :per_slot_option => true,
          :participant_visibility => true,
          :max_appointments_per_participant_option => true
      }
      # assert options are checked
      open_edit_dialog
      expect(f('[type=checkbox][name="per_slot_option"]').selected?).to be_truthy
      expect(f('[type=checkbox][name="participant_visibility"]').selected?).to be_truthy
      expect(f('[type=checkbox][name="max_appointments_per_participant_option"]').selected?).to be_truthy

      # uncheck the options
      f('[type=checkbox][name="per_slot_option"]').click
      f('[type=checkbox][name="participant_visibility"]').click
      f('[type=checkbox][name="max_appointments_per_participant_option"]').click
      submit_dialog('.ui-dialog-buttonset', '.ui-button')
      wait_for_ajaximations
      # assert options are not checked
      open_edit_dialog
      expect(f('[type=checkbox][name="per_slot_option"]').selected?).to be_falsey
      expect(f('[type=checkbox][name="participant_visibility"]').selected?).to be_falsey
      expect(f('[type=checkbox][name="max_appointments_per_participant_option"]').selected?).to be_falsey
    end

    it "should send messages to appropriate participants" do
      gc = group_category
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
          form = f('#message_participants_form')
          expect(form).to be_displayed
          wait_for_ajaximations

          set_value(form.find_element(:css, '.message_groups'), registration_status)
          wait_for_ajaximations

          expect(form.find_elements(:css, '.participant_list li')).not_to be_empty
          set_value(form.find_element(:css, '#body'), 'hello')
          submit_dialog(fj('.ui-dialog:visible'), '.ui-button')
          wait_for_ajaximations
          # using fj to avoid selenium caching
          keep_trying_until { expect(fj('#message_participants_form')).to be_nil }
        end
      end
      expect(student1.conversations.first.messages.size).to eq 6 # registered/all * 3
      expect(student2.conversations.first.messages.size).to eq 6 # unregistered/all * 2 + registered/all (ug1)
      expect(student3.conversations.first.messages.size).to eq 6 # unregistered/all * 3
      expect(student4.conversations.first.messages.size).to eq 4 # unregistered/all * 2 (not in any group)
      expect(student5.conversations.first.messages.size).to eq 2 # unregistered/all * 1 (doesn't meet any sub_context criteria)
    end

    it "should validate the appointment group shows up on the calendar" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      expect(element_exists('.fc-event-bg')).to be_truthy
    end

    it "should not allow limiting the max appointments per participant to less than 1" do
      get "/calendar2"
      click_scheduler_link
      fill_out_appointment_group_form('max appointments')

      # invalid max_appointments
      max_appointments_input = f('[name="max_appointments_per_participant"]')
      replace_content(max_appointments_input, '0')
      expect(get_value('[name="max_appointments_per_participant"]').to_i).to be > 0
    end

    it "should allow removing individual appointment users" do
      #set_native_events("false")
      # user appointment group
      create_appointment_group
      ag = AppointmentGroup.first
      2.times do
        student_in_course(:course => @course, :active_all => true)
        ag.appointments.first.reserve_for(@user, @user)
      end

      get "/calendar2"
      click_scheduler_link


      f(".appointment-group-item:nth-child(#{1}) .view_calendar_link").click
      wait_for_ajaximations
      sleep 1

      #driver.execute_script("$('.fc-event-title').hover().click()")
      #

      fj('.fc-event:visible').click

      wait_for_ajaximations

      keep_trying_until { expect(ffj('#attendees li').size).to eq 2 }

      # delete the first appointment
      driver.execute_script("$('.cancel_appointment_link:eq(1)').trigger('click')")
      wait_for_ajaximations
      driver.execute_script("$('.ui-dialog-buttonset .btn-primary').trigger('click')")
      wait_for_ajaximations
      expect(ff('#attendees li').size).to eq 1

      fj('.fc-event:visible').click

      keep_trying_until { expect(ff('#attendees li').size).to eq 1 }
      f('.scheduler_done_button').click
    end

    it "should allow removing individual appointment groups" do
      #set_native_events("false")
      # group appointment group
      gc = @course.group_categories.create!(:name => "Blah Groups")
      title = create_appointment_group :sub_context_codes => [gc.asset_string],
                                       :title => "group ag"
      ag = AppointmentGroup.where(title: title).first
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

      f(".appointment-group-item:nth-child(#{1}) .view_calendar_link").click
      wait_for_ajaximations
      fj('.fc-event:visible').click
      wait_for_ajaximations
      expect(ffj('#attendees li').size).to eq 2

      # delete the first appointment
      driver.execute_script("$('.cancel_appointment_link:eq(1)').trigger('click')")
      wait_for_ajaximations
      driver.execute_script("$('.ui-dialog-buttonset .btn-primary').trigger('click')")
      wait_for_ajaximations
      expect(ff('#attendees li').size).to eq 1

      fj('.fc-event:visible').click
      expect(ff('#attendees li').size).to eq 1
      f('.scheduler_done_button').click
    end

    it "should allow me to create a course with multiple contexts" do
      course1 = @course
      course_with_teacher(:user => @teacher, :active_all => true)
      get "/calendar2"
      click_scheduler_link
      fill_out_appointment_group_form('multiple contexts')
      f('.ag_contexts_selector').click
      ff('.ag_sections_toggle').last.click
      f("[value=#{course1.asset_string}]").click

      # sections should get checked by their parent
      section_box = f("[value=#{@course.course_sections.first.asset_string}]")
      expect(section_box[:checked]).to be_truthy

      # unchecking all sections should uncheck their parent
      course_box = f("[value=#{@course.asset_string}]")
      section_box.click
      expect(course_box[:checked]).to be_falsey

      # checking all sections should check parent
      section_box.click
      expect(course_box[:checked]).to be_truthy

      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajaximations
      ag = AppointmentGroup.first
      expect(ag.contexts).to include course1
      expect(ag.contexts).to include @course
      expect(ag.sub_contexts).to eq []
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
      expect(ag.appointments.first.participants_per_appointment).to eq 5
      expect(ag.participants_per_appointment).to eq 2

      open_edit_event_dialog
      f('[type=checkbox][name=max_participants_option]').click
      fj('.ui-button:contains(Update)').click
      wait_for_ajaximations

      ag.reload
      expect(ag.appointments.first.participants_per_appointment).to be_nil
    end
  end
end
