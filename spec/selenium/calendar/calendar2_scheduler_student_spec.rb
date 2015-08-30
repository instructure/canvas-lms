require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/scheduler_common')

describe "scheduler" do
  include_context "in-process server selenium tests"
  context "as a student" do

    before (:each) do
      Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
      course_with_student_logged_in
      make_full_screen
    end

    def reserve_appointment_manual(n)
      ffj('.fc-event')[n].click
      driver.execute_script("$('.event-details .reserve_event_link').trigger('click')")
      wait_for_ajax_requests
    end

    it "should let me reserve appointment groups for contexts I am in", :priority  => "1", test_id: 140195 do
      my_course = @course
      course_with_student(:active_all => true)
      other_course = @course

      create_appointment_group(:contexts => [other_course, my_course])

      get "/calendar2"
      click_scheduler_link
      wait_for_ajaximations
      click_appointment_link

      reserve_appointment_manual(0)
      expect(f('.fc-event')).to include_text "Reserved"
    end

    it "should allow me to cancel existing reservation and sign up for the appointment group from the calendar", priority: "1", test_id: 140200 do
      tomorrow = (Date.today + 1).to_s
      create_appointment_group(:max_appointments_per_participant => 1,
                               :new_appointments => [
                                   [tomorrow + ' 12:00:00', current_date = tomorrow + ' 13:00:00'],
                                   [tomorrow + ' 14:00:00', current_date = tomorrow + ' 15:00:00'],
                               ])
      get "/calendar2"
      click_scheduler_link
      click_appointment_link

      reserve_appointment_manual(0)
      expect(f('.fc-event')).to include_text "Reserved"

      # try to reserve the second appointment
      reserve_appointment_manual(1)
      fj('.ui-button:contains(Reschedule)').click
      wait_for_ajax_requests

      event1, event2 = ff('.fc-event')
      expect(event1).to include_text "Available"
      expect(event2).to include_text "Reserved"
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
      click_scheduler_link
      click_appointment_link

      reserve_appointment_manual(0)
      reserve_appointment_manual(1)
      e1, e2, *rest = ff('.fc-event')
      expect(e1).to include_text "Reserved"
      expect(e2).to include_text "Reserved"

      reserve_appointment_manual(2)
      fj('.ui-button:contains("OK")').click # "can't reserve" dialog
      expect(f('.fc-event:nth-child(3)')).to include_text "Available"
    end

    it "should allow other users to fill up available timeslots" do
      tomorrow = Time.zone.today.advance(days: 1).to_s
      create_appointment_group(:max_appointments_per_participant => 1,
                               :min_appointments_per_participant => 1,
                               :participants_per_appointment => 2,
                               :new_appointments => [
                                 [tomorrow + ' 12:00:00', tomorrow + ' 13:00:00'],
                                 [tomorrow + ' 14:00:00', tomorrow + ' 15:00:00']
                               ])

      # create some users to work with
      @student1, @student2, @student3 = create_users_in_course(@course, 3, return_type: :record)

      # first student grabs first seat in first timeslot
      user_session @student1
      @user = @student1

      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      reserve_appointment_manual(0)

      # second student grabs second seat in first timeslot
      user_session @student2
      @user = @student2

      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      reserve_appointment_manual(0)

      # third student should see second timeslot as available
      user_session @student3
      @user = @student3

      # signup link should still show up
      get "/calendar2"
      click_scheduler_link
      requiring_action = ff('.requiring-action')
      expect(requiring_action).to_not be_empty

      # first slot full, but second available
      click_appointment_link
      e1, e2 = ff('.fc-event')
      expect(e1).to include_text "Filled"
      expect(e2).to include_text "Available"
    end

    it "should not allow me to cancel reservations from the attendees list" do
      create_appointment_group
      ag = AppointmentGroup.first
      ag.appointments.first.reserve_for(@user, @user)
      get "/calendar2"
      click_scheduler_link
      wait_for_ajaximations
      click_appointment_link

      fj('.fc-event:visible').click
      expect(ff('#reservations').size).to be_zero
    end

    it "should check index page for correct element", priority: "1", test_id: 140217 do
      title = "blarg"
      location = "brighton"

      create_appointment_group(:location_name => location, :title => title)
      get "/calendar2"
      click_scheduler_link

      # Index page should show correct elements for appointment groups
      expect(f(".view_calendar_link").text).to include_text(title)
      expect(f(".ag-context").text).to include @course.name.to_s #include context
      expect(f(".ag-location").text).to include_text(location)
    end

    context "when un-reserving appointments" do
      before do
        date = Date.today.to_s
        create_appointment_group(
          max_appointments_per_participant: 1,
          new_appointments: [
            [date + ' 12:00:00', date + ' 13:00:00'],
            [date + ' 14:00:00', date + ' 15:00:00']
          ]
        )
        get "/calendar2"
        click_scheduler_link
        click_appointment_link

        reserve_appointment_manual(0)
      end

      it "should let me do so from the month view" do
        load_month_view

        fj('.fc-event.scheduler-event').click
        fj('.unreserve_event_link').click
        fj('#delete_event_dialog~.ui-dialog-buttonpane .btn-primary').click

        wait_for_ajaximations

        expect(fj('.fc-event.scheduler-event')).to be_nil
      end

      it "should let me do so from the week view" do
        load_week_view

        fj('.fc-event.scheduler-event').click
        fj('.unreserve_event_link').click
        fj('#delete_event_dialog~.ui-dialog-buttonpane .btn-primary').click

        wait_for_ajaximations

        expect(fj('.fc-event.scheduler-event')).to be_nil
      end
    end
  end
end
