# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
require_relative "pages/scheduler_page"

describe "scheduler" do
  include Calendar2Common
  include SchedulerPage
  include_context "in-process server selenium tests"

  context "as a teacher" do
    before(:once) do
      Account.default.settings[:show_scheduler] = true
      Account.default.save!
    end

    before do
      course_with_teacher_logged_in
    end

    it "shows Appointment Group tab with new scheduler feature flag turned on", priority: "1" do
      get "/calendar"
      calendar_create_event_button.click
      expect(f("#edit_event_tabs")).to contain_css(".edit_appointment_group_option")
    end

    it "shows correct title when editing an appointment group", priority: "1" do
      title = "Ultimate AG"
      create_appointment_group(title:)
      get "/calendar"
      # navigate to the next month for end of month
      f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
      f(".scheduler-event").click
      calendar_edit_event_link.click
      expect(fj("span.ui-dialog-title:contains('Edit #{title}')")).not_to be_nil
    end

    it "creates an Appointment Group with the feature flag ON", priority: "1" do
      title = "my appt"
      location = "office"
      start_time_text = "02"
      end_time_text = "05"

      get "/calendar"

      calendar_create_event_button.click
      wait_for_ajax_requests
      appointment_group_tab_button.click

      set_value(f('input[name="title"]'), title)
      set_value(f('input[name="location"]'), location)

      # select the first course calendar
      f(".select-calendar-container .ag_contexts_selector").click
      f('.ag-contexts input[type="checkbox"]').click
      f(".ag_contexts_done").click

      # select a proper appointment group time
      t = Time.zone.local(2016, 11, 7, 1, 0, 0)
      date = Time.zone.today.advance(years: 1).to_s
      Timecop.freeze(t) do
        fj(".ui-datepicker-trigger:visible").click
        datepicker_current
        set_value(fj(".time_field.start_time:visible"), start_time_text)
        set_value(fj(".time_field.end_time:visible"), end_time_text)
        set_value(fj(".date_field:visible"), date)
        find(".scheduler-event-details-footer .btn-primary").click
        wait_for_ajax_requests
      end

      # make sure that the DB record for the Appointment Group is correct
      last_group = AppointmentGroup.last
      expect(last_group.title).to eq title
      expect(last_group.location_name).to eq location
      expect(last_group.start_at.strftime("%I")).to eq start_time_text
      expect(last_group.end_at.strftime("%I")).to eq end_time_text
    end

    it "shows page for editing Appointment Groups", priority: "1" do
      create_appointment_group(contexts: [@course])
      get "/calendar2"
      # navigate to the next month for end of month
      f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
      f(".fc-title").click
      f(".pull-right .group_details").click
      expect(f(".EditPage")).to include_text("Edit new appointment group")
    end

    it "does not show the Find Appointment button for the teacher", priority: "1" do
      create_appointment_group title: "appointment1"
      get "/calendar"
      expect(f("#select-course-component")).not_to contain_css("#FindAppointmentButton")
    end

    it "linkifies links in appointment group description but not when editing description in modal" do
      description = "Submit document at http://google.com/submit"
      create_appointment_group(title: "Peer review session", description:)
      get "/calendar"
      # navigate to the next month for end of month
      f(".navigate_next").click unless Time.now.utc.month == (Time.now.utc + 1.day).month
      f(".scheduler-event").click
      expect(f(".event-detail-overflow")).to include_text(description)
      expect(f(".event-detail-overflow a")).to have_attribute("href", "http://google.com/submit")
      calendar_edit_event_link.click
      expect(f("#edit_appt_calendar_event_form textarea")).to include_text(description)
    end

    it "lets teachers allow observers to sign up only when selected contexts allow it" do
      course1 = @course
      course1.account.settings[:allow_observers_in_appointment_groups] = { value: true }
      course1.account.save!
      account2 = Account.default.sub_accounts.create!
      account2.settings[:allow_observers_in_appointment_groups] = { value: false }
      account2.settings[:show_scheduler] = true
      account2.save!
      course2 = course_factory(account: account2, active_all: true, name: "Course 2")
      course2.enroll_teacher(@user, enrollment_state: "active")
      get "/calendar"

      calendar_create_event_button.click
      wait_for_ajax_requests
      appointment_group_tab_button.click

      expect(allow_observer_signup_checkbox).not_to be_displayed
      select_context_in_context_selector(course1.id)
      expect(allow_observer_signup_checkbox).to be_displayed
      select_context_in_context_selector(course2.id)
      expect(allow_observer_signup_checkbox).not_to be_displayed
    end

    it "lets teachers edit appointment groups even if a context is concluded", :ignore_js_errors do
      course1 = @course
      course2 = course_factory(active_all: true, name: "Course 2")
      teacher_in_course(course: course2, user: @user, active_all: true)
      create_appointment_group(contexts: [course1, course2])
      course1.conclude_at = 1.week.ago
      course1.restrict_enrollments_to_course_dates = true
      course1.save!
      ag = AppointmentGroup.last

      get "/appointment_groups/#{ag.id}/edit"
      wait_for_ajaximations
      location = "office"
      location_input.send_keys(location)
      click_save_button
      expect(ag.reload.location_name).to eq(location)
    end

    context "Message Students" do
      it "sends individual messages to students who have not signed up", :ignore_js_errors do
        create_appointment_group(contexts: [@course])
        student1 = student_in_course(active_all: true, name: "Student 1").user
        student2 = student_in_course(active_all: true, name: "Student 2").user
        ag = AppointmentGroup.last

        get "/appointment_groups/#{ag.id}/edit"
        click_message_students_button
        wait_for_ajax_requests
        body = "Please sign up for this appointment group"
        message_body_textarea.send_keys(body)
        click_send_message_button
        messages = ConversationMessage.last(2)
        expect(messages.count).to be 2
        messages.each do |m|
          expect(m.body).to eq body
          expect(m.recipients.count).to be 1
        end
        recipient_ids = messages.map { |m| m.recipients.first.id }
        expect(recipient_ids).to contain_exactly(student1.id, student2.id)
      end
    end
  end
end
