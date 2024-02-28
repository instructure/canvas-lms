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
require_relative "pages/calendar_page"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include CalendarPage

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

    it "navigates to month view when month button is clicked", :xbrowser do
      load_week_view
      f("#month").click
      wait_for_ajaximations
      expect(fj(".fc-month-view:visible")).to be_present
    end

    describe "main month calendar" do
      it "remembers the selected calendar view" do
        get "/calendar2"
        expect(find("#month")).to have_class("active")
        find("#agenda").click
        wait_for_ajaximations

        get "/calendar2"
        expect(find("#agenda")).to have_class("active")
      end

      it "creates an event through clicking on a calendar day", priority: "1" do
        create_middle_day_event
      end

      it "creates an assignment by clicking on a calendar day" do
        create_middle_day_assignment
      end

      it "translates am/pm time strings in assignment event datepicker", priority: "2" do
        skip("CNVS-28437")
        @user.locale = "fa"
        @user.save!
        load_month_view
        calendar_create_event_button.click
        f("#edit_event .edit_assignment_option").click
        f("#assignment_title").send_keys("test assignment")
        f("#edit_assignment_form .ui-datepicker-trigger.btn").click
        wait_for_ajaximations
        expect(f("#ui-datepicker-div .ui-datepicker-time-ampm")).to include_text("قبل از ظهر")
        expect(f("#ui-datepicker-div .ui-datepicker-time-ampm")).to include_text("بعد از ظهر")
      end

      context "drag and drop" do
        def element_location
          driver.execute_script("return $('#calendar-app .fc-content-skeleton:first')
          .find('tbody td.fc-event-container').index()")
        end

        before do
          @monday = 1
          @friday = 5
          @initial_time = Time.zone.parse("2015-1-1").beginning_of_day + 9.hours
          @initial_time_str = @initial_time.strftime("%Y-%m-%d")
          @one_day_later = @initial_time + 24.hours
          @one_day_later_str = @one_day_later.strftime("%Y-%m-%d")
          @three_days_earlier = @initial_time - 72.hours
        end

        it "drags and drop assignment override forward" do
          assignment1 = @course.assignments.create!(title: "new month view assignment")
          assignment1.assignment_overrides.create! do |override|
            override.set = @course.course_sections.first
            override.due_at = @initial_time
            override.due_at_overridden = true
          end
          get "/calendar2"
          quick_jump_to_date(@initial_time_str)

          # Move assignment from Thursday to Friday
          drag_and_drop_element(find(".calendar .fc-event"),
                                find(".calendar .fc-day.fc-widget-content.fc-fri.fc-past"))

          # Expect no pop up errors with drag and drop
          expect_no_flash_message :error

          # Assignment should be moved to Friday
          expect(element_location).to eq @friday

          # Assignment time should stay at 9:00am
          assignment1.reload
          expect(assignment1.assignment_overrides.first.due_at).to eql(@one_day_later)
        end

        it "drags and drop assignment forward", priority: "1" do
          assignment1 = @course.assignments.create!(title: "new month view assignment", due_at: @initial_time)
          get "/calendar2"
          quick_jump_to_date(@initial_time_str)

          # Move assignment from Thursday to Friday
          drag_and_drop_element(find(".calendar .fc-event"),
                                find(".calendar .fc-day.fc-widget-content.fc-fri.fc-past"))

          # Expect no pop up errors with drag and drop
          expect_no_flash_message :error

          # Assignment should be moved to Friday
          expect(element_location).to eq @friday

          # Assignment time should stay at 9:00am
          assignment1.reload
          expect(assignment1.start_at).to eql(@one_day_later)
        end

        it "drags and drop event forward", priority: "1" do
          event1 = make_event(start: @initial_time, title: "new week view event")
          get "/calendar2"
          quick_jump_to_date(@initial_time_str)

          # Move event from Thursday to Friday
          drag_and_drop_element(find(".calendar .fc-event"),
                                find(".calendar .fc-day.fc-widget-content.fc-fri.fc-past"))

          # Expect no pop up errors with drag and drop
          expect_no_flash_message :error

          # Event should be moved to Friday
          expect(element_location).to eq @friday

          # Event time should stay at 9:00am
          event1.reload
          expect(event1.start_at).to eql(@one_day_later)
        end

        it "drags and drop assignment back", priority: "1" do
          assignment1 = @course.assignments.create!(title: "new month view assignment", due_at: @initial_time)
          get "/calendar2"
          quick_jump_to_date(@initial_time_str)

          # Move assignment from Thursday to Monday
          drag_and_drop_element(find(".calendar .fc-event"),
                                find(".calendar .fc-day.fc-widget-content.fc-mon.fc-past"))

          # Expect no pop up errors with drag and drop
          expect_no_flash_message :error

          # Assignment should be moved to Monday
          expect(element_location).to eq @monday

          # Assignment time should stay at 9:00am
          assignment1.reload
          expect(assignment1.start_at).to eql(@three_days_earlier)
        end

        it "drags and drop event back", priority: "1" do
          event1 = make_event(start: @initial_time, title: "new week view event")
          get "/calendar2"
          quick_jump_to_date(@initial_time_str)

          # Move event from Thursday to Monday
          drag_and_drop_element(find(".calendar .fc-event"),
                                find(".calendar .fc-day.fc-widget-content.fc-mon.fc-past"))

          # Expect no pop up errors with drag and drop
          expect_no_flash_message :error

          # Event should be moved to Monday
          expect(element_location).to eq @monday

          # Event time should stay at 9:00am
          event1.reload
          expect(event1.start_at).to eql(@three_days_earlier)
        end

        it "extends event to multiple days by draging", priority: "2" do
          skip("dragging events are flaky and need more research FOO-4335")

          create_middle_day_event
          date_of_middle_day = find_middle_day.attribute("data-date")
          date_of_next_day = (date_of_middle_day.to_datetime + 1.day).strftime("%Y-%m-%d")
          f(".fc-content-skeleton .fc-event-container .fc-resizer")
          next_day = fj("[data-date=#{date_of_next_day}]")
          drag_and_drop_element(f(".fc-content-skeleton .fc-event-container .fc-resizer"), next_day)
          fj(".fc-event:visible").click
          # observe the event details show date range from event start to date to end date
          original_day_text = format_time_for_view(date_of_middle_day.to_datetime)
          extended_day_text = format_time_for_view(date_of_next_day.to_datetime + 1.day)
          expect(f(".event-details-timestring .date-range").text).to eq("#{original_day_text} - #{extended_day_text}")
        end
      end

      it "more options link should go to calendar event edit page" do
        create_middle_day_event
        f(".fc-event").click
        expect(fj(".popover-links-holder:visible")).not_to be_nil
        hover_and_click ".edit_event_link"
        expect_new_page_load { edit_calendar_event_form_more_options.click }
        expect(find("#editCalendarEventFull .btn-primary").text).to eq "Update Event"
        expect(find("#breadcrumbs")).to include_text "Calendar Events"
      end

      it "goes to assignment page when clicking assignment title" do
        name = "special assignment"
        create_middle_day_assignment(name)
        f(".fc-event.assignment").click
        expect_new_page_load { hover_and_click ".view_event_link" }
        expect(f("h1.title")).to be_displayed

        expect(find("h1.title")).to include_text(name)
      end

      it "more options link on assignments should go to assignment edit page" do
        name = "super big assignment"
        create_middle_day_assignment(name)
        f(".fc-event.assignment").click
        hover_and_click ".edit_event_link"
        expect_new_page_load { f(".more_options_link").click }
        expect(find("#assignment_name").attribute(:value)).to include(name)
      end

      it "publishes a new assignment when toggle is clicked" do
        create_published_middle_day_assignment
        f(".fc-event.assignment").click
        hover_and_click ".edit_event_link"
        expect_new_page_load { f(".more_options_link").click }
        expect(find("#assignment-draft-state")).not_to include_text("Not Published")
      end

      it "deletes an event" do
        create_middle_day_event("doomed event")
        f(".fc-event").click
        hover_and_click ".delete_event_link"
        click_delete_confirm_button
        expect(f("#content")).not_to contain_jqcss(".fc-event:visible")
        # make sure it was actually deleted and not just removed from the interface
        get("/calendar2")
        expect(f("#content")).not_to contain_jqcss(".fc-event:visible")
      end

      it "deletes an assignment" do
        create_middle_day_assignment
        f(".fc-event").click
        hover_and_click ".delete_event_link"
        click_delete_confirm_button
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css(".fc-event")
        # make sure it was actually deleted and not just removed from the interface
        get("/calendar2")
        expect(f("#content")).not_to contain_css(".fc-event")
      end

      it "does not have a delete link for a frozen assignment" do
        allow(PluginSetting).to receive(:settings_for_plugin).and_return({ "assignment_group_id" => "true" })
        frozen_assignment = @course.assignments.build(
          name: "frozen assignment",
          due_at: Time.zone.now,
          freeze_on_copy: true
        )
        frozen_assignment.copied = true
        frozen_assignment.save!

        get("/calendar2")
        fj(".fc-event:visible").click
        expect(f("body")).not_to contain_css(".delete_event_link")
      end

      it "displays next month on arrow press", priority: "1" do
        load_month_view
        quick_jump_to_date("Jan 1, 2012")
        change_calendar(:next)

        # Verify known dates in calendar header and grid
        expect(header_text).to include("February 2012")
        first_wednesday = ".fc-day-top.fc-wed:first"
        expect(fj(first_wednesday).text).to eq("1")
        expect(fj(first_wednesday)).to have_attribute("data-date", "2012-02-01")
        last_thursday = ".fc-day-top.fc-thu:last"
        expect(fj(last_thursday).text).to eq("1")
        expect(fj(last_thursday)).to have_attribute("data-date", "2012-03-01")
      end

      it "displays previous month on arrow press", priority: "1" do
        load_month_view
        quick_jump_to_date("Jan 1, 2012")
        change_calendar(:prev)

        # Verify known dates in calendar header and grid
        expect(header_text).to include("December 2011")
        first_thursday = ".fc-day-top.fc-thu:first"
        expect(fj(first_thursday).text).to eq("1")
        expect(fj(first_thursday)).to have_attribute("data-date", "2011-12-01")
        last_saturday = ".fc-day-top.fc-sat:last"
        expect(fj(last_saturday).text).to eq("31")
        expect(fj(last_saturday)).to have_attribute("data-date", "2011-12-31")
      end

      it "fixes up the event's date for events after 11:30pm" do
        time = Time.zone.now.at_beginning_of_day + 23.hours + 45.minutes
        @course.calendar_events.create! title: "ohai", start_at: time, end_at: time + 5.minutes

        load_month_view

        expect(fj(".fc-event .fc-time").text).to eq("11:45p")
      end

      it "changes the month" do
        get "/calendar2"
        old_header_title = header_text
        change_calendar
        new_header_title = header_text
        expect(old_header_title).not_to eq new_header_title
      end

      it "navigates with jump-to-date control" do
        Account.default.change_root_account_setting!(:agenda_view, true)
        # needs to be 2 months out so it doesn't appear at the start of the next month
        eventStart = 2.months.from_now
        make_event(start: eventStart)

        get "/calendar2"
        expect(f("#content")).not_to contain_css(".fc-event")
        eventStartText = eventStart.strftime("%Y %m %d")
        quick_jump_to_date(eventStartText)
        expect(find(".fc-event")).to be
      end

      it "shows section-level events, but not the parent event" do
        @course.default_section.update_attribute(:name, "default section!")
        s2 = @course.course_sections.create!(name: "other section!")
        date = Date.today
        e1 = @course.calendar_events.build title: "ohai",
                                           child_event_data: [
                                             { start_at: "#{date} 12:00:00", end_at: "#{date} 13:00:00", context_code: @course.default_section.asset_string },
                                             { start_at: "#{date} 13:00:00", end_at: "#{date} 14:00:00", context_code: s2.asset_string },
                                           ]
        e1.updating_user = @user
        e1.save!

        get "/calendar2"
        events = ffj(".fc-event:visible")
        expect(events.size).to eq 2
        events.first.click

        details = find(".event-details")
        expect(details).to be
        expect(details.text).to include(@course.default_section.name)
        expect(details.find(".view_event_link")[:href]).to include "/calendar_events/#{e1.id}" # links to parent event
      end

      it "has a working today button", priority: "1" do
        load_month_view
        date = Time.now.strftime("%-d")

        # Check for highlight to be present on this month
        # this class is also present on the mini calendar so we need to make
        #   sure that they are both present
        expect(find_all(".fc-today").size).to eq 4

        # Switch the month and verify that there is no highlighted day
        2.times { change_calendar }
        expect(f("body")).not_to contain_css(".fc-today")

        # Go back to the present month. Verify that there is a highlighted day
        change_calendar(:today)
        expect(find_all(".fc-today").size).to eq 4
        # Check the date in the second instance which is the main calendar
        expect(ff(".fc-today")[1].text).to include(date)
      end

      it "shows the location when clicking on a calendar event" do
        location_name = "brighton"
        location_address = "cottonwood"
        make_event(location_name:, location_address:)
        load_month_view

        # Click calendar item to bring up event summary
        find(".fc-event").click

        # expect to find the location name and address
        expect(find(".event-details-content")).to include_text(location_name)
        expect(find(".event-details-content")).to include_text(location_address)
      end

      it "brings up a calendar date picker when clicking on the month" do
        load_month_view

        # Click on the month header
        find(".navigation_title").click

        # Expect that a the event picker is present
        # Check various elements to verify that the calendar looks good
        expect(find(".ui-datepicker-header")).to include_text(Time.now.utc.strftime("%B"))
        expect(find(".ui-datepicker-calendar")).to include_text("Mo")
      end

      it "strikethroughs past due assignment", priority: "1" do
        date_due = Time.zone.now.utc - 2.days
        @assignment = @course.assignments.create!(
          title: "new outdated assignment",
          name: "new outdated assignment",
          due_at: date_due
        )
        get "/calendar2"

        # go to the same month as the date_due
        quick_jump_to_date(date_due.strftime("%Y-%m-%d"))

        # verify assignment has line-through
        expect(find(".fc-title").css_value("text-decoration")).to include("line-through")
      end

      it "strikethroughs past due graded discussion", priority: "1" do
        date_due = Time.zone.now.utc - 2.days
        a = @course.assignments.create!(title: "past due assignment", due_at: date_due, points_possible: 10)
        @pub_graded_discussion_due = @course.discussion_topics.build(assignment: a, title: "graded discussion")
        @pub_graded_discussion_due.save!
        get "/calendar2"

        # go to the same month as the date_due
        quick_jump_to_date(date_due.strftime("%Y-%m-%d"))

        # verify discussion has line-through
        expect(find(".fc-title").css_value("text-decoration")).to include("line-through")
      end

      it "returns back to the original calendar view after editing a section child event" do
        calendar_event_model(start_at: "Sep 3 2008", title: "some event")
        child = @event.child_events.build
        child.context = @course.course_sections.create!
        child.start_at = Time.zone.now.utc
        child.title = "the real event"
        child.save!

        get "/calendar2"
        quick_jump_to_date(child.start_at.strftime("%Y-%m-%d"))
        f(".fc-event").click

        hover_and_click ".edit_event_link"
        expect_new_page_load { edit_calendar_event_form_more_options.click }
        cancel_btn = f(".form-actions a")
        expect(cancel_btn.text).to eq "Cancel"
        expect(cancel_btn["href"]).to include("view_name=month")
        expect(cancel_btn["href"]).to_not include(@course.asset_string)
      end
    end
  end

  context "as a student" do
    before do
      course_with_student_logged_in
    end

    it "navigates to month view when month button is clicked" do
      load_week_view
      f("#month").click
      wait_for_ajaximations
      expect(fj(".fc-month-view:visible")).to be_present
    end

    describe "main month calendar" do
      it "strikethroughs completed assignment title", priority: "1" do
        date_due = Time.zone.now.utc + 2.days
        @assignment = @course.assignments.create!(
          title: "new outdated assignment",
          name: "new outdated assignment",
          due_at: date_due,
          submission_types: "online_text_entry"
        )

        # submit assignment
        submission = @assignment.submit_homework(@student)
        submission.submission_type = "online_text_entry"
        submission.save!
        get "/calendar2"

        # go to the same month as the date_due
        quick_jump_to_date(date_due.strftime("%Y-%m-%d"))

        # verify assignment has line-through
        expect(find(".fc-title").css_value("text-decoration")).to include("line-through")
      end

      it "strikethroughs completed graded discussion", priority: "1" do
        date_due = Time.zone.now.utc + 2.days
        reply = "Replying to discussion"

        a = @course.assignments.create!(title: "past due assignment", due_at: date_due, points_possible: 10)
        @pub_graded_discussion_due = @course.discussion_topics.build(assignment: a, title: "graded discussion")
        @pub_graded_discussion_due.save!

        get "/courses/#{@course.id}/discussion_topics/#{@pub_graded_discussion_due.id}"
        find(".discussion-reply-action").click
        type_in_tiny(".reply-textarea", reply)
        find(".btn.btn-primary").click
        wait_for_ajaximations
        get "/calendar2"

        # go to the same month as the date_due
        quick_jump_to_date(date_due.strftime("%Y-%m-%d"))

        # verify discussion has line-through
        expect(find(".fc-title").css_value("text-decoration")).to include("line-through")
      end

      it "loads events from adjacent months correctly" do
        time = DateTime.parse("2016-04-01")
        @course.calendar_events.create! title: "aprilfools", start_at: time, end_at: time + 5.minutes

        get "/calendar2"

        quick_jump_to_date("2016-03-31") # jump to previous month
        expect(find(".fc-title")).to include_text("aprilfools") # should show event at end of week

        quick_jump_to_date("2016-04-01") # jump to next month
        expect(find(".fc-title")).to include_text("aprilfools") # should still load cached event
      end

      it "doesn't duplicate events when enabling calendars" do
        time = DateTime.parse("2016-04-01")
        @course.calendar_events.create! title: "aprilfools", start_at: time, end_at: time + 5.minutes
        get "/calendar2?include_contexts=#{@course.asset_string}#view_name=month&view_start=2016-04-01"
        wait_for_ajaximations
        expect(ff(".fc-title").count).to be(1)
        f(".context-list-toggle-box.group_#{@student.asset_string}").click
        wait_for_ajaximations
        expect(ff(".fc-title").count).to be(1)
        expect(f(".fc-title")).to include_text("aprilfools") # should still load cached event
      end
    end
  end
end
