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
    Account.default.tap do |a|
      a.settings[:show_scheduler] = true
      a.save!
    end
  end

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
    end

    context "week view" do
      it "navigates to week view when week button is clicked", :xbrowser, priority: "2" do
        load_week_view
        expect(fj(".fc-agendaWeek-view:visible")).to be_present
      end

      # TODO: reimplement per CNVS-29592, but make sure we're testing at the right level
      it "should render assignments due just before midnight"

      it "shows manual assignment event due saturday after 6pm", priority: "1" do
        load_week_view
        calendar_create_event_button.click
        wait_for_ajaximations
        event_dialog = f("#edit_event_tabs")
        event_dialog.find(".edit_assignment_option").click
        wait_for_ajaximations
        event_dialog.find("#assignment_title").send_keys("saturday assignment")
        # take next week's monday and advance to saturday from the current date
        due_date = "Dec 26, 2015 at 8pm"
        due_date_field = event_dialog.find(".datetime_field")
        replace_content(due_date_field, due_date)
        driver.action.send_keys(due_date_field, :return)
        assignment_form = event_dialog.find("#edit_assignment_form")
        submit_form(assignment_form)
        wait_for_ajaximations
        quick_jump_to_date("Dec 26, 2015")
        f(".fc-event").click
        wait_for_ajaximations

        expect(f(".event-details-timestring")).to include_text("Due: #{due_date}")
      end

      it "shows short events at full height", priority: "2" do
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        @course.calendar_events.create! title: "ohai", start_at: noon, end_at: noon + 5.minutes

        load_week_view

        elt = fj(".fc-event:visible")
        expect(elt.size.height).to be >= 18
      end

      it "fixes up the event's data-start for events after 11:30pm", priority: "2" do
        time = Time.zone.now.at_beginning_of_day + 23.hours + 45.minutes
        @course.calendar_events.create! title: "ohai", start_at: time, end_at: time + 5.minutes

        load_week_view

        expect(f(".fc-event .fc-time")).to have_attribute("data-start", "11:45")
      end

      it "staggers pseudo-overlapping short events", priority: "2" do
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        first_event = @course.calendar_events.create! title: "ohai", start_at: noon, end_at: noon + 5.minutes
        second_start = first_event.start_at + 6.minutes
        @course.calendar_events.create!(title: "ohai", start_at: second_start, end_at: second_start + 5.minutes)

        load_week_view

        elts = ffj(".fc-event:visible")
        expect(elts.size).to be(2)

        elt_lefts = elts.map { |elt| elt.location.x }.uniq
        expect(elt_lefts.size).to eql(elts.size)
      end

      it "does not change duration when dragging a short event", priority: "2" do
        skip("dragging events doesn't seem to work FOO-4335")
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! title: "ohai", start_at: noon, end_at: noon + 5.minutes
        load_week_view

        elt = fj(".fc-event:visible")
        driver.action.drag_and_drop_by(elt, 0, 50)
        wait_for_ajax_requests
        expect(event.reload.start_at).to eql(noon + 1.hour)
        expect(event.reload.end_at).to eql(noon + 1.hour + 5.minutes)
      end

      it "doesn't change the time when dragging an event close to midnight", priority: "2" do
        # Choose a fixed date to avoid periodic end-of-week failures
        close_to_midnight = Time.zone.parse("2015-1-1").beginning_of_day + 1.day - 20.minutes

        # Create a target event because positioning on the calendar is hard
        make_event(title: "Event1", start: close_to_midnight + 1.day)

        # The event to be dragged
        event2 = make_event(title: "Event2", start: close_to_midnight, end: close_to_midnight + 15.minutes)

        load_week_view
        quick_jump_to_date("Jan 1, 2015")
        expect(ff(".fc-event")).to have_size(2)
        events = ff(".fc-event")

        # Scroll the elements into view
        scroll_into_view(".fc-event")

        # Drag object event onto target event
        driver.action.move_to(events[0]).click_and_hold.move_to(events[1]).release.perform
        wait_for_ajaximations

        expect(event2.reload.start_at).to eql(close_to_midnight + 1.day)
        expect(event2.end_at).to eql(close_to_midnight + 1.day + 15.minutes)
      end

      it "shows the right times in the tool tips for short events", priority: "2" do
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        @course.calendar_events.create! title: "ohai", start_at: noon, end_at: noon + 5.minutes
        load_week_view

        elt = fj(".fc-event:visible")
        expect(elt).to have_attribute("title", /12:00.*12:05/)
      end
    end

    it "displays correct dates after navigation arrow", priority: "1" do
      load_week_view
      quick_jump_to_date("Jan 1, 2012")
      change_calendar(:next)

      # Verify Week and Day labels are correct
      expect(header_text).to include("Jan 8 – 14, 2012")
      expect(f(".fc-sun")).to include_text("SUN 1/8")
    end

    it "creates event by clicking on week calendar", priority: "1" do
      skip("fickle VICE-5319")
      title = "from clicking week calendar"
      load_week_view

      # Click non all-day event
      fj(".fc-agendaWeek-view .fc-time-grid .fc-slats .fc-widget-content:not(.fc-axis):first").click
      event_from_modal(title, false, false)
      expect(f(".fc-title")).to include_text title
    end

    it "creates all day event on week calendar", priority: "1" do
      title = "all day event title"
      load_week_view

      # click all day event
      f(".fc-agendaWeek-view .fc-week .fc-wed").click
      event_from_modal(title, false, false)
      expect(f(".fc-title")).to include_text title
    end

    it "has a working today button", priority: "1" do
      load_week_view

      # Mini calendar on the right of page has this html element I am looking for so
      #   when checking for "today", we need to look for the second instance of the class

      # Check for highlight to be present on this week
      expect(ff(".fc-agendaWeek-view .fc-today").size).to eq 3

      # Change calendar week until the highlight is not there (it should eventually)
      2.times { change_calendar }
      expect(f(".fc-agendaWeek-view")).not_to contain_css(".fc-today")

      # Back to today. Make sure that the highlight is present again
      change_calendar(:today)
      expect(ff(".fc-agendaWeek-view .fc-today").size).to eq 3
    end

    it "shows the location when clicking on a calendar event", priority: "2" do
      location_name = "brighton"
      location_address = "cottonwood"

      # Make it an all day event so it will be visible on the screen/on top
      make_event(location_name:, all_day: true, location_address:)
      load_week_view

      # Click calendar item to bring up event summary
      f(".fc-event").click

      # expect to find the location name and address
      expect(f(".event-details-content")).to include_text(location_name)
      expect(f(".event-details-content")).to include_text(location_address)
    end

    it "brings up a calendar date picker when clicking on the week range", priority: "2" do
      load_week_view
      # Click on the week header
      f(".navigation_title").click

      # Expect that a the event picker is present
      # Check various elements to verify that the calendar looks good
      expect(f(".ui-datepicker-header")).to include_text(Time.now.utc.strftime("%B"))
      expect(f(".ui-datepicker-calendar")).to include_text("Mo")
    end

    it "extends event time by dragging", priority: "1" do
      skip("dragging events are flaky and need more research FOO-4335")

      # Create event on current day at 9:00 AM in current time zone
      midnight = Time.zone.now.beginning_of_day
      event1 = make_event(start: midnight + 9.hours, end_at: midnight + 10.hours)

      # Create an assignment at noon to be the drag target
      #   This is a workaround because the rows do not have usable unique identifiers
      @course.assignments.create!(name: "Title", due_at: midnight + 12.hours)

      # Drag and drop event resizer from first event onto assignment icon
      load_week_view
      expect(ff(".fc-view-container .icon-calendar-month")).to have_size(1)

      # Calendar currently has post loading javascript that places the calendar event
      # In the correct place, however we don't have a wait_ajax_animation that waits
      # Long enough for this spec to pass given that we drag too soon causing it to fail
      disable_implicit_wait do
        keep_trying_until(10) do
          # Verify Event now ends at assignment start time + 30 minutes
          drag_and_drop_element(f(".fc-end-resizer"), f(".icon-assignment"))
          expect(event1.reload.end_at).to eql(midnight + 12.hours + 30.minutes)
        end
      end
    end

    it "makes event all-day by dragging", priority: "1" do
      skip "drag event isn't happening, might be a :timezone: :bomb:"

      # Create an all-day event to act as drag target
      #   This is a workaround because the all-day row is positioned absolutely
      midnight = Time.zone.now.beginning_of_day
      make_event(title: "Event1", start: midnight, all_day: true)

      # Create a second event, starting at noon, to be drag object
      event2 = make_event(title: "Event2", start: midnight + 12.hours)

      # Drag object event onto target event using calendar icons
      load_week_view
      expect(ff(".fc-view-container .icon-calendar-month")).to have_size(2)
      icon_array = ff(".fc-view-container .icon-calendar-month")
      drag_and_drop_element(icon_array[1], icon_array[0])
      wait_for_ajaximations

      # Verify object event is now all-day
      expect(event2.reload.all_day).to be(true)
      expect(event2.start_at).to eql(midnight)
    end

    context "drag and drop" do
      before do
        @saturday = 8
        @initial_time = Time.zone.parse("2015-1-1").beginning_of_day + 9.hours
        @initial_time_str = @initial_time.strftime("%Y-%m-%d")
        @two_days_later = @initial_time + 48.hours
      end

      it "drags and drop assignment", priority: "1" do
        assignment1 = @course.assignments.create!(title: "new week view assignment", due_at: @initial_time)

        # Workaround because the rows do not have usable unique identifiers
        @course.assignments.create!(name: "Assignment target", due_at: @two_days_later)

        load_week_view
        quick_jump_to_date(@initial_time_str)

        # Drag and drop assignment to new date
        icon_array = ff(".fc-view-container .icon-assignment")
        drag_and_drop_element(icon_array[0], icon_array[1])
        expect_no_flash_message :error

        # Assignment should be due on Saturday
        expect(fj("#calendar-app .fc-time-grid-container .fc-content-skeleton td:nth-child(#{@saturday})
         .fc-time-grid-event:contains(#{assignment1.title})")).to be_present

        # Assignment time should stay at 9:00am
        assignment1.reload
        expect(assignment1.start_at).to eql(@two_days_later)
      end

      it "drags and drop event", priority: "1" do
        event1 = make_event(start: @initial_time, title: "new week view event")

        # Workaround because the rows do not have usable unique identifiers
        make_event(start: @two_days_later, title: "Event Target")

        load_week_view
        quick_jump_to_date(@initial_time_str)

        # Drag and drop event to new date
        icon_array = ff(".fc-view-container .icon-calendar-month")
        drag_and_drop_element(icon_array[0], icon_array[1])
        expect_no_flash_message :error

        # Event should be due on Saturday
        expect(fj("#calendar-app .fc-time-grid-container .fc-content-skeleton td:nth-child(#{@saturday})
         .fc-time-grid-event:contains(#{event1.title})")).to be_present

        # Calendar item time should stay at 9:00am
        event1.reload
        expect(event1.start_at).to eql(@two_days_later)
      end

      it "extends all day event by dragging", priority: "2" do
        skip("dragging events are flaky and need more research FOO-4335")

        start_at_time = Time.zone.today.at_beginning_of_week(:sunday).beginning_of_day
        event = make_event(title: "Event1", start: start_at_time, all_day: true)
        load_week_view
        drag_and_drop_element(f(".fc-resizer"),
                              f(".fc-row .fc-content-skeleton td:nth-of-type(4)"))
        event.reload
        expect(event.end_at).to eq(start_at_time + 3.days)
      end
    end
  end

  context "as a student" do
    before do
      course_with_student_logged_in
    end

    it "navigates to week view when week button is clicked" do
      load_week_view
      expect(fj(".fc-agendaWeek-view:visible")).to be_present
    end
  end
end
