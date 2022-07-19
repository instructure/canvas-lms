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

  before do
    Account.default.tap do |a|
      a.settings[:show_scheduler] = true
      a.save!
    end
  end

  context "as a student" do
    before do
      @student = course_with_student_logged_in(active_all: true).user
    end

    describe "main calendar" do
      context "the event modal" do
        it "allows other users to see attendees after reservation" do
          create_appointment_group(
            contexts: [@course],
            title: "eh",
            max_appointments_per_participant: 1,
            min_appointments_per_participant: 1,
            participants_per_appointment: 2,
            participant_visibility: "protected"
          )
          ag1 = AppointmentGroup.first
          # create and reserver two participants into appointmentgroup
          ag1.appointments.first.reserve_for @student, @student
          student2 = student_in_course(course: @course, active_all: true).user
          ag1.appointments.first.reserve_for student2, student2
          get "/calendar2"
          # navigate to the next month for end of month
          f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
          fj(".fc-event:visible").click
          wait_for_ajaximations
          expect(f("#reservations li")).to include_text "nobody@example.com"
        end

        it "allows users to see all attendees on events up to 25 reservations" do
          create_appointment_group(
            contexts: [@course],
            title: "eh",
            max_appointments_per_participant: 1,
            min_appointments_per_participant: 1,
            participants_per_appointment: 15,
            participant_visibility: "protected"
          )
          ag1 = AppointmentGroup.first
          ag1.appointments.first.reserve_for @student, @student
          students = create_users_in_course(@course, 12, return_type: :record)
          students.each do |student_temp|
            ag1.appointments.first.reserve_for student_temp, student_temp
          end
          get "/calendar2"
          f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
          fj(".fc-event:visible").click
          wait_for_ajaximations
          expected_string = "Attendees\nnobody@example.com\n#{students.map(&:name).join("\n")}"
          expect(f("#reservations")).to include_text expected_string
        end

        it "shows dots indicating more users available if more than 25 reservations" do
          create_appointment_group(
            contexts: [@course],
            title: "eh",
            max_appointments_per_participant: 1,
            min_appointments_per_participant: 1,
            participants_per_appointment: 27,
            participant_visibility: "protected"
          )
          ag1 = AppointmentGroup.first
          ag1.appointments.first.reserve_for @student, @student
          students = create_users_in_course(@course, 25, return_type: :record)
          students.each do |student_temp|
            ag1.appointments.first.reserve_for student_temp, student_temp
          end
          get "/calendar2"
          f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
          fj(".fc-event:visible").click
          wait_for_ajaximations
          expected_string = "Attendees\nnobody@example.com\n#{students[0, 24].map(&:name).join("\n")}\n(...)"
          expect(f("#reservations")).to include_text expected_string
        end

        it "does not display attendees for reservation with no participants" do
          create_appointment_group(
            contexts: [@course],
            title: "eh",
            max_appointments_per_participant: 1,
            min_appointments_per_participant: 1,
            participants_per_appointment: 2,
            participant_visibility: "protected"
          )
          ag1 = AppointmentGroup.first
          ag1.appointments.first.reserve_for @student, @student
          get "/calendar2"
          # navigate to the next month for end of month
          f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
          fj(".fc-event:visible").click
          f(".unreserve_event_link").click
          fj("button:contains('Delete')").click
          wait_for_ajaximations
          expect(f(".fc-body")).not_to contain_css(".fc-event")
        end
      end

      it "shows section-level events for the student's section" do
        @course.default_section.update_attribute(:name, "default section!")
        s2 = @course.course_sections.create!(name: "other section!")
        date = Date.today
        e1 = @course.calendar_events.build title: "ohai",
                                           child_event_data: [
                                             { start_at: "#{date} 12:00:00", end_at: "#{date} 13:00:00", context_code: s2.asset_string },
                                             { start_at: "#{date} 13:00:00", end_at: "#{date} 14:00:00", context_code: @course.default_section.asset_string },
                                           ]
        e1.updating_user = @teacher
        e1.save!

        get "/calendar2"
        events = ff(".fc-event")
        expect(events.size).to eq 1
        expect(events.first.text).to include "1p"
        expect(events.first).not_to have_class "fc-draggable"
        events.first.click

        details = f(".event-details-content")
        expect(details).not_to be_nil
        expect(details.text).to include(@course.default_section.name)
      end

      it "displays title link and go to event details page" do
        make_event(context: @course, start: 0.days.from_now, title: "future event")
        get "/calendar2"

        # click the event in the calendar
        fj(".fc-event").click
        expect(fj("#popover-0")).to be_displayed
        expect_new_page_load { driver.execute_script("$('.view_event_link').hover().click()") }

        page_title = f(".title")
        expect(page_title).to be_displayed
        expect(page_title.text).to eq "future event"
      end

      it "does not redirect but load the event details page" do
        event = make_event(context: @course, start: 2.months.from_now, title: "future event")
        get "/courses/#{@course.id}/calendar_events/#{event.id}"
        page_title = f(".title")
        expect(page_title).to be_displayed
        expect(page_title.text).to eq "future event"
      end

      it "lets the group members create a calendar event for the group", priority: "1" do
        group = @course.groups.create!(name: "Test Group")
        group.add_user @student
        group.save!
        get "/calendar2"
        move_to_click_element(fj(".calendar .fc-week .fc-today"))
        edit_event_dialog = f("#edit_event_tabs")
        expect(edit_event_dialog).to be_displayed
        title = edit_calendar_event_form_title
        replace_content(title, "Test Event")
        replace_content(edit_calendar_event_start_input, "6:00am")
        replace_content(edit_calendar_event_end_input, "6:00pm")
        click_option(edit_calendar_event_form_context, group.name)
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        expect(CalendarEvent.last.title).to eq("Test Event")
      end
    end
  end

  context "as a spanish student" do
    before do
      # Setup with spanish locale
      @student = course_with_student_logged_in(active_all: true).user
      @student.locale = "es"
      @student.save!
    end

    describe "main calendar" do
      it "displays in Spanish" do
        skip("USE_OPTIMIZED_JS=true") unless ENV["USE_OPTIMIZED_JS"]
        skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
        date = Date.new(2012, 7, 12)
        # Use event to  open to a specific and testable month
        event = calendar_event_model(title: "Test Event", start_at: date, end_at: (date + 1.hour))

        get "/courses/#{@course.id}/calendar_events/#{event.id}?calendar=1"
        expect(fj(".calendar_header .navigation_title").text).to eq "julio 2012"
        expect(fj("#calendar-app .fc-sun").text).to eq "DOM."
        expect(fj("#calendar-app .fc-mon").text).to eq "LUN."
        expect(fj("#calendar-app .fc-tue").text).to eq "MAR."
        expect(fj("#calendar-app .fc-wed").text).to eq "MIÉ."
        expect(fj("#calendar-app .fc-thu").text).to eq "JUE."
        expect(fj("#calendar-app .fc-fri").text).to eq "VIE."
        expect(fj("#calendar-app .fc-sat").text).to eq "SÁB."
      end
    end

    describe "mini calendar" do
      it "displays in Spanish" do
        skip("USE_OPTIMIZED_JS=true") unless ENV["USE_OPTIMIZED_JS"]
        skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
        get "/calendar2"
        # Get the spanish text for the current month/year
        expect_month_year = I18n.l(Date.today, format: "%B %Y", locale: "es")
        expect(fj("#minical h2").text).to eq expect_month_year.downcase
      end
    end
  end
end
