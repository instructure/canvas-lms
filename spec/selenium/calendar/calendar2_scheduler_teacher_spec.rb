require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/scheduler_common')

describe "scheduler" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include SchedulerCommon

  context "as a teacher" do

    before(:once) do
      Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
      course_with_teacher(active_all: true)
    end

    before(:each) do
      user_session(@teacher)
      make_full_screen
    end

    it "should bring up 'edit appointment group' modal when clicking 'create an appointment group' scheduler button" do
      get "/calendar2#view_name=scheduler"
      f('#right-side .create_link').click
      expect(f('#edit_event')).not_to be_nil
    end

    it "should not enforce minimum event lengths when loading appointment times into the edit group form" do
      date = Date.today.to_s
      create_appointment_group(:new_appointments => [[date + ' 12:00:00', date + ' 12:13:00']])
      get "/calendar2#view_name=scheduler"
      click_appointment_link
      click_al_option('.edit_link')
      expect(f('.end_time')['value']).to include(":13")
    end

    it "should split time slots", priority: "1", test_id: 140190 do
      start_time_text = '02'
      end_time_text = '06'

      get "/calendar2#view_name=scheduler"
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
      times.each_with_index do |time, i|
        field = start_fields[i]
        expect(field.attribute(:value).strip).to eq time + "am"
      end
      f('.ag_contexts_selector').click
      f("#option_course_#{@course.id}").click
      f('.ag_contexts_done').click
      submit_appointment_group_form
      last_group = AppointmentGroup.last

      expect(last_group.end_at.strftime("%I")).to eq end_time_text
      expect(last_group.start_at.strftime("%I")).to eq start_time_text
    end

    it "should require at least one time slot" do
      get "/calendar2#view_name=scheduler"
      f('.create_link').click
      fj('.ui-datepicker-trigger:visible').click
      datepicker_next
      set_value(f('.start_time'), '01')

      # Need to submit manually to avoid waiting for ajaximations, which
      # causes Selenium to blow up when it sees the alert we're expecting
      _, save_and_publish = ff('.ui-dialog-buttonset .ui-button')
      save_and_publish.click

      expect(driver.switch_to.alert.text).to be_present
      driver.switch_to.alert.accept
    end

    it "should allow checkboxes in the options section to be edited" do
      get "/calendar2#view_name=scheduler"
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

    it "should send messages to appropriate participants", priority: "1", test_id: 140192 do
      student1 = student_in_course(:course => @course, :active_all => true).user
      student2 = student_in_course(:course => @course, :active_all => true).user

      # create an appointment groups and sign up a participant
      appointment_participant_model(:course => @course, :participant => student1)

      get "/calendar2#view_name=scheduler"

      appointment_group = f('.appointment-group-item')
      hover(appointment_group)
      click_al_option('.message_link', 0)
      form = f('#message_participants_form')
      expect(form).to be_displayed
      set_value(form.find('.message_groups'), 'registered')
      wait_for_ajax_requests

      expect(form.find_all('.participant_list li')).not_to be_empty
      set_value(form.find('#body'), 'hello')
      submit_dialog(fj('.ui-dialog:visible'), '.ui-button')
      wait_for_ajax_requests
      expect(student1.conversations.first.messages.size).to eq 1
      expect(student2.conversations.size).to eq 0
    end

    it "should use the correct context for messages sent through scheduler" do
      student1 = student_in_course(:course => @course, :active_all => true).user
      appointment_participant_model(:course => @course, :participant => student1)

      first_course = @course

      other_course = course_factory
      other_course.enroll_teacher(@teacher).accept!
      other_course.offer
      other_course.enroll_student(student1).accept!

      get "/calendar2#view_name=scheduler"

      hover f('.appointment-group-item')

      click_al_option('.message_link')
      form = f('#message_participants_form')
      expect(form).to be_displayed

      set_value(form.find('.message_groups'), "all")
      wait_for_ajax_requests

      expect(form.find_all('.participant_list li')).not_to be_empty
      set_value(form.find('#body'), 'hello')
      submit_dialog(fj('.ui-dialog:visible'), '.ui-button')
      wait_for_ajax_requests

      part1 = student1.conversations.first
      expect(part1.tags).to eq ["course_#{first_course.id}"]
      part2 = @teacher.all_conversations.first
      expect(part2.tags).to eq ["course_#{first_course.id}"]
    end

    it "should validate the appointment group shows up on the calendar", priority: "1", test_id: 140193 do
      date = Time.zone.today.to_s
      create_appointment_group(:new_appointments => [
        [date + ' 12:00:00', date + ' 13:00:00'],
      ])
      get "/calendar2#view_name=scheduler"
      click_appointment_link
      expect(f('.agenda-event__item .agenda-event__item-container')).to be_present
    end

    it "should validate the appointment group shows on all views after a student signed up", priority: "1", test_id: 1729408 do
      date = Time.zone.today.to_s
      create_appointment_group(:new_appointments => [
        [date + ' 12:00:00', date + ' 13:00:00'],
      ])
      ag = AppointmentGroup.first
      student_in_course(course: @course, active_all: true)
      ag.appointments.first.reserve_for(@user, @user, comments: 'this is important')
      load_month_view
      expect(f('.fc-content .fc-title').text).to include('new appointment group')
      f('#week').click
      expect(f('.fc-content .fc-title').text).to include('new appointment group')
      f('#agenda').click
      expect(f('.agenda-event__item .agenda-event__item-container').text).to include('new appointment group')
    end

    it "should not allow limiting the max appointments per participant to less than 1", priority: "1", test_id: 140194 do
      get "/calendar2#view_name=scheduler"
      fill_out_appointment_group_form('max appointments')

      # invalid max_appointments
      max_appointments_input = f('[name="max_appointments_per_participant"]')
      replace_content(max_appointments_input, '0')

      f('.ui-dialog-buttonset .Button--primary').click
      assert_error_box('[name="max_appointments_per_participant"]')
    end

    it "should show appointment notes",:priority => "1", test_id: 140195 do
      create_appointment_group
      ag = AppointmentGroup.first
      student_in_course(:course => @course, :active_all => true)
      ag.appointments.first.reserve_for(@user, @user, comments: 'this is important')

      get "/calendar2#view_name=scheduler"
      f(".appointment-group-item:nth-child(1) .view_calendar_link").click

      f('.agenda-event__item .agenda-event__item-container').click

      expect(ff('#attendees li')).to have_size(1)

      expect(f('.event-details-content')).to include_text "this is important"
    end

    it "should allow removing individual appointment users",:priority  => "1", test_id: 140196 do
      # user appointment group
      create_appointment_group
      ag = AppointmentGroup.first
      2.times do
        student_in_course(:course => @course, :active_all => true)
        ag.appointments.first.reserve_for(@user, @user, comments: 'this is important')
      end

      get "/calendar2#view_name=scheduler"

      f(".appointment-group-item:nth-child(1) .view_calendar_link").click

      f('.agenda-event__item .agenda-event__item-container').click

      expect(ff('#attendees li')).to have_size(2)

      # delete the first appointment
      fj('.cancel_appointment_link:eq(1)').click
      f('.ui-dialog-buttonset .btn-primary').click
      expect(ff('#attendees li')).to have_size(1)

      f('.agenda-event__item .agenda-event__item-container').click

      expect(ff('#attendees li')).to have_size(1)
    end

    it "should allow removing individual appointment groups" do
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

      get "/calendar2#view_name=scheduler"

      f(".appointment-group-item:nth-child(1) .view_calendar_link").click
      fj('.agenda-event__item .agenda-event__item-container').click
      expect(ff('#attendees li')).to have_size 2

      # delete the first appointment
      fj('.cancel_appointment_link:eq(1)').click
      f('.ui-dialog-buttonset .btn-primary').click
      expect(ff('#attendees li')).to have_size 1

      f('.agenda-event__item .agenda-event__item-container').click
      expect(ff('#attendees li')).to have_size 1
    end

    # TODO reimplement per CNVS-29591, but make sure we're testing at the right level
    it "should allow me to create a course with multiple contexts"

    it "should allow me to override the participant limit on a slot-by-slot basis" do
      create_appointment_group :participants_per_appointment => 2
      get "/calendar2#view_name=scheduler"
      click_appointment_link

      open_edit_appointment_group_event_dialog
      replace_content f('[name=max_participants]'), "5"
      fj('.ui-button:contains(Update)').click
      wait_for_ajaximations

      ag = AppointmentGroup.first
      expect(ag.appointments.first.participants_per_appointment).to eq 5
      expect(ag.participants_per_appointment).to eq 2

      open_edit_appointment_group_event_dialog
      f('[type=checkbox][name=max_participants_option]').click
      fj('.ui-button:contains(Update)').click
      wait_for_ajaximations

      ag.reload
      expect(ag.appointments.first.participants_per_appointment).to be_nil
    end
  end
end
