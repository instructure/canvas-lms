# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
require_relative "../helpers/scheduler_common"
require_relative "pages/calendar_page"

describe "scheduler" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include SchedulerCommon
  include CalendarPage

  context "as a student" do
    before(:once) do
      Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
      course_with_student(active_all: true)
    end

    before do
      user_session(@student)
    end

    def reserve_appointment_manual(n, comment = nil)
      all_agenda_items[n].click
      if comment
        # compiled/util/Popover sets focus on the close button twice
        # within the first 100ms, which can cause it to hijack
        # keypresses, making a " " close the modal
        sleep 0.1
        replace_content(f("#appointment-comment"), comment)
      end
      f(".reserve_event_link").click
      wait_for_ajaximations
    end

    it "reserves appointment groups via Find Appointment mode" do
      my_course = @course
      create_appointment_group(contexts: [my_course])
      get "/calendar2#view_name=week&view_start=#{(Date.today + 1.day).strftime}"
      find_appointment_button.click
      f('[role="dialog"][aria-label="Select Course"] button[type="submit"]').click
      wait_for_ajaximations
      # wait for loading spinner to be gone
      wait_for(method: nil, timeout: 2) { !f("#refresh_calendar_link").displayed? }
      scheduler_event.click
      f(".reserve_event_link").click
      # wait for loading spinner before wait for ajax
      wait_for(method: nil, timeout: 2) { f("#refresh_calendar_link").displayed? }
      wait_for_ajaximations
      find_appointment_button.click
      expect(scheduler_event).to include_text "new appointment group"
    end

    it "reserves group appointment groups via Find Appointment Mode" do
      gc = @course.group_categories.create!(name: "Blah Groups")
      group = gc.groups.create! name: "Blah Group", context: @course
      group.add_user @student
      create_appointment_group(sub_context_codes: [gc.asset_string], title: "Bleh Group Thing")
      get "/calendar2#view_name=week&view_start=#{(Date.today + 1.day).strftime}"
      find_appointment_button.click
      f('[role="dialog"][aria-label="Select Course"] button[type="submit"]').click
      wait_for_ajaximations
      # wait for loading spinner to be gone
      wait_for(method: nil, timeout: 2) { !f("#refresh_calendar_link").displayed? }
      scheduler_event.click
      f(".reserve_event_link").click
      # wait for loading spinner before wait for ajax
      wait_for(method: nil, timeout: 2) { f("#refresh_calendar_link").displayed? }
      wait_for_ajaximations
      find_appointment_button.click
      expect(scheduler_event).to include_text "Bleh Group Thing"
    end

    context "when un-reserving appointments" do
      let(:earliest_appointment_time) { 30.minutes.from_now }

      before :once do
        create_appointment_group(
          max_appointments_per_participant: 1,
          # if participant_visibility is 'private', the event_details popup resizes,
          # causing fragile tests in Chrome
          participant_visibility: "protected",
          new_appointments: [
            [earliest_appointment_time, 1.hour.from_now]
          ]
        )
        AppointmentGroup.last.appointments.first.reserve_for(@student, @teacher)
      end

      it "lets me do so from the month view", priority: "1" do
        load_month_view

        scheduler_event.click
        f(".event-details .unreserve_event_link").click
        wait_for_ajaximations
        click_delete_confirm_button

        expect(f("#content")).not_to contain_css(".fc-event.scheduler-event")
      end

      it "lets me do so from the week view", priority: "1" do
        # the setup creates an event 30 minutes from now, so if we're on Saturday
        # and next Sunday is in 30 minutes, this test will fail
        skip("too close to week rollover") if Time.now.saturday? && earliest_appointment_time.sunday?
        load_week_view

        scheduler_event.click
        wait_for_ajaximations
        f(".event-details .unreserve_event_link").click
        wait_for_ajaximations
        click_delete_confirm_button

        expect(f("#content")).not_to contain_css(".fc-event.scheduler-event")
      end

      it "lets me do so from the agenda view", priority: "1" do
        load_agenda_view

        agenda_item.click
        f(".event-details .unreserve_event_link").click
        wait_for_ajaximations
        click_delete_confirm_button

        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
      end
    end

    it "does not allow unreserving past appointments" do
      create_appointment_group(
        max_appointments_per_participant: 1,
        new_appointments: [
          # this can fail if run in the first 2 seconds of the month.
          [2.seconds.ago, 1.second.ago]
        ]
      )
      AppointmentGroup.last.appointments.first.reserve_for(@student, @teacher)

      load_month_view

      scheduler_event.click
      expect(f(".event-details")).not_to contain_css(".unreserve_event_link")
    end
  end
end
