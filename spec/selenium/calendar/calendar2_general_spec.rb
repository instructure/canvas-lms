# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../common"
require_relative "../helpers/calendar2_common"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:once) do
    Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
  end

  before do
    # or some stuff we need to click is "below the fold"

    Account.default.tap do |a|
      a.settings[:show_scheduler] = true
      a.save!
    end
  end

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
    end

    it "lets me go to the Edit Appointment group page from the appointment group slot dialog" do
      date = Time.zone.today.to_s
      create_appointment_group new_appointments: [
        ["#{date} 12:00:00", "#{date} 13:00:00"],
        ["#{date} 13:00:00", "#{date} 14:00:00"],
      ]

      get "/calendar2"

      f(".fc-event").click
      wait_for_ajaximations
      expect_new_page_load { f(".group_details").click }
      wait_for_ajaximations
      expect(driver.current_url).to include("appointment_groups/#{AppointmentGroup.last.id}/edit")
    end

    it "lets me message students who have signed up for an appointment" do
      date = Time.zone.today.to_s
      create_appointment_group new_appointments: [
        ["#{date} 12:00:00", "#{date} 13:00:00"],
        ["#{date} 13:00:00", "#{date} 14:00:00"],
      ]
      student1, student2 = Array.new(2) do
        student_in_course course: @course, active_all: true
        @student
      end
      app1, app2 = AppointmentGroup.first.appointments
      app1.reserve_for(student1, student1)
      app2.reserve_for(student2, student2)

      get "/calendar2"
      fj(".fc-event").click
      wait_for_ajaximations

      driver.execute_script("$('.message_students').hover().click()")

      wait_for_ajaximations
      expect(ff(".participant_list input").size).to eq 1
      set_value f('textarea[name="body"]'), "hello"
      fj(".ui-button:contains(Send)").click
      wait_for_ajaximations

      expect(student1.conversations.first.messages.size).to eq 1
      expect(student2.conversations).to be_empty
    end

    context "assignments" do
      it "editing an existing assignment should select the correct assignment group" do
        group1 = @course.assignment_groups.create!(name: "Assignment Group 1")
        group2 = @course.assignment_groups.create!(name: "Assignment Group 2")
        @course.active_assignments.create(name: "Assignment 1", assignment_group: group1, due_at: Time.zone.now)
        assignment2 = @course.active_assignments.create(name: "Assignment 2", assignment_group: group2, due_at: Time.zone.now)

        get "/calendar2"
        events = ff(".fc-event")
        event1 = events.detect { |e| e.text.include?("Assignment 1") }
        event2 = events.detect { |e| e.text.include?("Assignment 2") }
        expect(event1).not_to be_nil
        expect(event2).not_to be_nil
        expect(event1).not_to eq event2

        event1.click
        wait_for_ajaximations
        driver.execute_script("$('.edit_event_link').hover().click()")
        wait_for_ajaximations

        select = f("#edit_assignment_form .assignment_group")
        expect(first_selected_option(select).attribute(:value).to_i).to eq group1.id
        close_visible_dialog

        event2.click
        wait_for_ajaximations

        driver.execute_script("$('.edit_event_link').hover().click()")
        wait_for_ajaximations
        select = f("#edit_assignment_form .assignment_group")
        expect(first_selected_option(select).attribute(:value).to_i).to eq group2.id
        replace_content(f(".ui-dialog #assignment_title"), "Assignment 2!")
        submit_form("#edit_assignment_form")
        wait_for_ajaximations
        expect(assignment2.reload.title).to include("Assignment 2!")
        expect(assignment2.assignment_group).to eq group2
      end

      it "editing an existing assignment should preserve more options link", priority: "1" do
        assignment = @course.active_assignments.create!(name: "to edit", due_at: Time.zone.now)
        get "/calendar2"
        f(".fc-event").click
        wait_for_ajaximations
        hover_and_click ".edit_event_link"
        wait_for_ajaximations
        original_more_options = f(".more_options_link")["href"]
        expect(original_more_options).not_to match(/undefined/)
        replace_content(f(".ui-dialog #assignment_title"), "edited title")
        submit_form("#edit_assignment_form")
        wait_for_ajaximations
        assignment.reload
        wait_for_ajaximations
        expect(assignment.title).to include("edited title")

        f(".fc-event").click
        wait_for_ajaximations
        hover_and_click ".edit_event_link"
        wait_for_ajaximations
        expect(f(".more_options_link")["href"]).to match(original_more_options)
      end

      it "makes an assignment undated if you delete the start date" do
        skip_if_chrome("can not replace content")
        create_middle_day_assignment("undate me")
        f(".fc-event:not(.event_pending)").click
        hover_and_click ".popover-links-holder .edit_event_link"
        expect(f(".ui-dialog #assignment_due_at")).to be_displayed

        replace_content(f(".ui-dialog #assignment_due_at"), "")
        submit_form("#edit_assignment_form")
        wait_for_ajax_requests
        f("#undated-events-button").click
        expect(f("#content")).not_to contain_css(".fc-event")
        expect(f(".undated_event_title")).to include_text("undate me")
      end

      it "course pacing calendars' assignments should not appear on teachers' calendars" do
        Account.site_admin.enable_feature! :account_level_blackout_dates
        @course.enable_course_paces = true
        @course.save!
        @course.active_assignments.create!(name: "cp assignment", due_at: Time.zone.now)
        get "/calendar2"
        expect(f("#content")).not_to contain_css(".fc-event")
      end
    end

    context "event editing", priority: "1" do
      it "allows editing appointment events" do
        create_appointment_group
        ag = AppointmentGroup.first
        student_in_course(course: @course, active_all: true)
        ag.appointments.first.reserve_for(@user, @user)

        get "/calendar2"

        # navigate to the next month for end of month
        f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
        open_edit_event_dialog
        description = "description..."
        replace_content f("[name=description]"), description
        fj(".ui-button:contains(Update)").click
        wait_for_ajaximations

        expect(ag.reload.appointments.first.description).to eq description
        expect(f(".fc-event")).to be
      end

      it "allows moving events between calendars" do
        event = @user.calendar_events.create! title: "blah", start_at: Time.zone.today
        get "/calendar2"
        open_edit_event_dialog
        click_option(edit_calendar_event_form_context, @course.name)
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        expect(event.reload.context).to eq @course
        expect(f(".fc-event")).to have_class "group_course_#{@course.id}"
      end

      it "does not allow saving events without participants" do
        skip("VICE-5309 - flaky")
        create_appointment_group
        ag = AppointmentGroup.first
        student_in_course(course: @course, active_all: true)
        ag.appointments.first.reserve_for(@user, @user)

        get "/calendar2"

        open_edit_event_dialog
        f("[type=checkbox][name=max_participants_option]").click
        replace_content f("[name=max_participants]"), 0
        fj(".ui-button:contains(Update)").click
        wait_for_ajaximations

        expect(f(".error-message").text).to include "Please enter a value greater or equal to 1"
      end
    end

    context "time zone" do
      before do
        @user.time_zone = "America/Denver"
        @user.save!
      end

      it "displays popup with correct day on an event" do
        local_now = @user.time_zone.now
        event_start = @user.time_zone.local(local_now.year, local_now.month, 15, 22, 0, 0)
        make_event(start: event_start)
        get "/calendar2"
        f(".fc-event").click
        expect(f(".event-details-timestring").text).to include event_start.strftime("%b %e")
      end

      it "displays popup with correct day on an assignment" do
        local_now = @user.time_zone.now
        event_start = @user.time_zone.local(local_now.year, local_now.month, 15, 22, 0, 0)
        @course.assignments.create!(
          title: "test assignment",
          due_at: event_start
        )
        get "/calendar2"
        f(".fc-event").click
        expect(f(".event-details-timestring").text).to include event_start.strftime("%b %e")
      end

      it "displays popup with correct day on an assignment override" do
        @student = course_with_student_logged_in.user
        @student.time_zone = "America/Denver"
        @student.save!

        local_now = @user.time_zone.now
        assignment_start = @user.time_zone.local(local_now.year, local_now.month, 15, 22, 0, 0)
        assignment = @course.assignments.create!(title: "test assignment", due_at: assignment_start)

        override_start = @user.time_zone.local(local_now.year, local_now.month, 20, 22, 0, 0)
        override = assignment.assignment_overrides.create! do |o|
          o.title = "test override"
          o.set_type = "ADHOC"
          o.due_at = override_start
          o.due_at_overridden = true
        end
        override.assignment_override_students.create! do |link|
          link.user = @student
          link.assignment_override = override
        end

        get "/calendar2"
        f(".fc-event").click
        expect(f(".event-details-timestring").text).to include override_start.strftime("%b %e")
      end

      it "handles events created on daylight savings time days" do
        late_march = @user.time_zone.local(2021, 3, 28, 3, 0, 0)
        new_date = @user.time_zone.local(2021, 3, 14, 3, 0, 0)
        start_time = "3:00 AM"
        end_time = "4:00 AM"
        Timecop.freeze(late_march) do
          get "/calendar2#view_name=month&view_start=2021-03-01"
          find_middle_day.click
          replace_content(edit_calendar_event_form_title, "Timed Event")
          replace_content(edit_calendar_event_form_date, format_date_for_view(new_date, :medium))
          edit_calendar_event_start_input.click
          replace_content(edit_calendar_event_start_input, start_time)
          edit_calendar_event_start_input.send_keys :return
          edit_calendar_event_end_input.click
          replace_content(edit_calendar_event_end_input, end_time)
          edit_calendar_event_end_input.send_keys :return
          edit_calendar_event_form_submit_button.click
          wait_for_ajaximations
          refresh_page
          f(".fc-event").click
          expect(f(".event-details-timestring").text).to eq("Mar 14, 2021, 3am - 4am")
        end
      end
    end

    it "tests the today button" do
      get "/calendar2"
      current_month_num = Time.zone.now.month
      current_month = Date::MONTHNAMES[current_month_num]

      change_calendar
      expect(header_text).not_to eq current_month
      change_calendar(:today)
      expect(header_text).to eq(current_month + " " + Time.zone.now.year.to_s)
    end

    it "allows viewing an unenrolled calendar via include_contexts" do
      # also make sure the redirect from calendar -> calendar2 keeps the param
      unrelated_course = Course.create!(account: Account.default, name: "unrelated course")
      # make the user an admin so they can view the course's calendar without an enrollment
      Account.default.account_users.create!(user: @user)
      CalendarEvent.create!(title: "from unrelated one", start_at: Time.zone.now, end_at: 5.hours.from_now) { |c| c.context = unrelated_course }
      keep_trying_until { expect(CalendarEvent.last.title).to eq "from unrelated one" }
      get "/courses/#{unrelated_course.id}/settings"
      expect(f("#course_calendar_link")["href"]).to match(/course_#{Course.last.id}/)
      f("#course_calendar_link").click

      # only the explicit context should be selected
      expect(f("#calendars-context-list li[data-context=course_#{unrelated_course.id}].checked")).to be_truthy
      expect(f("#calendars-context-list li[data-context=course_#{@course.id}].not-checked")).to be_truthy
      expect(f("#calendars-context-list li[data-context=user_#{@user.id}].not-checked")).to be_truthy
    end

    it "only considers active enrollments for upcoming events list", priority: "2" do
      make_event(title: "Test Event", start: 1.day.from_now, context: @course)
      get "/"
      expect(f(".coming_up").text).to include("Test Event")
      term = EnrollmentTerm.find(@course.enrollment_term_id)
      term.end_at = Time.zone.now.advance(days: -5)
      term.save!
      refresh_page
      expect(f(".coming_up")).to include_text("Nothing for the next week")
    end

    it "graded discussion appears on all calendars", priority: "1" do
      skip("LS-3479 -- flay about 16% of the time for no apparent reason")
      create_graded_discussion

      # Even though graded discussion overwrites its assignment's title, less fragile to grab discussion's title
      assert_views(@gd.title, @assignment.due_at)
    end

    it "event appears on all calendars", priority: "1" do
      skip("LS-3421 -- flaky about 20% of the time")
      title = "loom"
      due_time = 5.minutes.from_now
      @course.calendar_events.create!(title:, start_at: due_time)

      assert_views(title, due_time)
    end

    it "assignment appears on all calendars", priority: "1" do
      skip("LS-3626 -- flaky about 20% of the time -- probably related to the others above")
      title = "Zak McKracken"
      due_time = 5.minutes.from_now
      @assignment = @course.assignments.create!(name: title, due_at: due_time)

      assert_views(title, due_time)
    end

    it "quiz appears on all calendars", priority: "1" do
      skip("LS-3626 -- flaky about 20% of the time -- probably related to the others above")
      create_quiz

      assert_views(@quiz.title, @quiz.due_at)
    end
  end

  context "as a user" do
    it "without enrollment in a course calendar appears" do
      user = user_factory(name: "user1", active_user: true)
      user_session(user)
      get "/calendar2"
      expect(f(".navigate_today")).to be_displayed
    end
  end
end
