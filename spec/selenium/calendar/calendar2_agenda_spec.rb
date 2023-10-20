# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

    context "agenda view" do
      before do
        account = Account.default
        account.settings[:agenda_view] = true
        account.save!
      end

      it "creates a new event via plus button", priority: "1" do
        load_agenda_view

        # Clicks plus button, saves event, and verifies a row has been added
        expect(fj(".agenda-wrapper:visible")).to be_present
        calendar_create_event_button.click
        replace_content(edit_calendar_event_form_title, "Test event")
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        expect(all_agenda_items.length).to eq 1
      end

      it "displays agenda events", :xbrowser do
        load_agenda_view
        expect(fj(".agenda-wrapper:visible")).to be_present
      end

      it "sets the header in the format 'Oct 11, 2013'", priority: "1" do
        start_date = Time.zone.now.beginning_of_day + 12.hours
        @course.calendar_events.create!(title: "ohai",
                                        start_at: start_date,
                                        end_at: start_date + 1.hour)
        load_agenda_view
        expect(agenda_view_header.text).to match(/[A-Z][a-z]{2}\s\d{1,2},\s\d{4}/)
      end

      it "respects context filters" do
        start_date = Time.now.utc.beginning_of_day + 12.hours
        @course.calendar_events.create!(title: "ohai",
                                        start_at: start_date,
                                        end_at: start_date + 1.hour)
        load_agenda_view
        expect(all_agenda_items.length).to eq 1
        fj(".context-list-toggle-box:last").click
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
      end

      it "is navigable via the jump-to-date control" do
        yesterday = 1.day.ago
        make_event(start: yesterday)
        load_agenda_view
        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
        quick_jump_to_date(yesterday.strftime("%b %-d %Y"))
        wait_for_ajaximations
        expect(all_agenda_items.length).to eq 1
      end

      it "is navigable via the minical" do
        yesterday = 1.day.ago
        make_event(start: yesterday)
        load_agenda_view
        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
        f(".fc-prev-button").click
        f("#right-side .fc-day-number").click
        expect(all_agenda_items.length).to eq 1
      end

      it "persists the start date across reloads" do
        load_agenda_view
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        refresh_page
        wait_for_ajaximations
        expect(agenda_view_header).to include_text(next_year)
      end

      it "transfers the start date when switching views" do
        get "/calendar2"
        f(".navigate_next").click
        f("#agenda").click
        expect(agenda_view_header).to include_text(1.month.from_now.strftime("%b"))
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        f("#month").click
        expect(agenda_view_header).to include_text(next_year)
      end

      it "displays the displayed date range in the header" do
        tomorrow = 1.day.from_now
        make_event(start: tomorrow)
        load_agenda_view

        expect(agenda_view_header).to include_text(format_date_for_view(Time.zone.now, :medium))
        expect(agenda_view_header).to include_text(format_date_for_view(tomorrow, :medium))
      end

      it "does not display a date range if no events are found" do
        load_agenda_view
        expect(agenda_view_header).not_to include_text("Invalid")
      end

      it "allows deleting events", priority: "1" do
        tomorrow = 3.days.from_now
        make_event(start: tomorrow)

        load_agenda_view
        expect(agenda_item_title).to include_text("User Event")

        agenda_item.click
        delete_event_button.click
        click_delete_confirm_button
        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
      end

      it "allows deleting assignments", priority: "1" do
        title = "Maniac Mansion"
        @assignment = @course.assignments.create!(name: title, due_at: 3.days.from_now)

        load_agenda_view
        expect(agenda_item_title).to include_text(title)

        agenda_item.click
        delete_event_button.click
        click_delete_confirm_button

        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
      end

      it "allows deleting a quiz", priority: "1" do
        create_quiz

        load_agenda_view
        expect(agenda_item_title).to include_text("Test Quiz")

        agenda_item.click
        delete_event_button.click
        click_delete_confirm_button

        expect(f("#content")).not_to contain_css(".agenda-event__item-container")
      end

      it "displays midnight assignments at 11:59" do
        assignment_model(course: @course,
                         title: "super important",
                         due_at: Time.zone.now.beginning_of_day + 1.day - 1.minute)
        expect(@assignment.due_date).to eq (Time.zone.now.beginning_of_day + 1.day - 1.minute).to_date

        load_agenda_view

        expect(f(".agenda-event__time")).to include_text("11:59")
        agenda_item.click
        expect(fj(".event-details:visible time")).to include_text("11:59")
      end

      it "has a working today button", priority: "1" do
        load_month_view
        # Go to a future calendar date to test going back
        change_calendar

        # Get the current date and make sure it is not in the header
        date = format_date_for_view(Time.zone.now, :medium)
        expect(agenda_view_header.text).not_to include(date)

        # Go the agenda view and click the today button
        f("#agenda").click
        wait_for_ajaximations
        change_calendar(:today)

        # Make sure that today's date is in the header
        expect(agenda_view_header.text).to include(date)
      end

      it "shows the location when clicking on a calendar event", priority: "1" do
        location_name = "brighton"
        location_address = "cottonwood"
        make_event(location_name:, location_address:)
        load_agenda_view

        # Click calendar item to bring up event summary
        agenda_item.click

        # expect to find the location name and address
        expect(f(".event-details-content")).to include_text(location_name)
        expect(f(".event-details-content")).to include_text(location_address)
      end

      it "brings up a calendar date picker when clicking on the agenda range", priority: "1" do
        load_agenda_view

        # Click on the agenda header
        agenda_view_header.click

        # Expect that a the event picker is present
        # Check various elements to verify that the calendar looks good
        expect(f(".ui-datepicker-header")).to include_text(Time.now.utc.strftime("%B"))
        expect(f(".ui-datepicker-calendar")).to include_text("Mo")
      end

      it "show quizes on agenda view", priority: "1" do
        create_quiz

        load_agenda_view
        expect(agenda_item).to include_text("Test Quiz")
      end

      it "shows assignment due dates for different sections", priority: "1" do
        assignment = @course.assignments.create!(name: "Test Title", due_at: 1.day.from_now)

        # Create Sections and Differentiated Assignment
        s1 = @course.course_sections.create!(name: "Section1")
        s2 = @course.course_sections.create!(name: "Section2")
        s1_date = rand(2...9).day.from_now
        s2_date = s1_date + 1.day
        @override = create_section_override_for_assignment(assignment, course_section: s1, due_at: s1_date)
        @override = create_section_override_for_assignment(assignment, course_section: s2, due_at: s2_date)

        load_agenda_view
        expect(all_agenda_items).to have_size(3)

        # Verify Titles include section name
        agenda_array = all_agenda_items
        expect(f(".agenda-event__title", agenda_array[1])).to include_text("Section1")
        expect(f(".agenda-event__title", agenda_array[2])).to include_text("Section2")

        # Verify Dates
        date_array = ff(".agenda-day")
        expect(f(".agenda-date", date_array[1])).to include_text(format_date_for_view(s1_date, :short_with_weekday))
        expect(f(".agenda-date", date_array[2])).to include_text(format_date_for_view(s2_date, :short_with_weekday))
      end

      context "with a graded discussion created" do
        before do
          create_graded_discussion
        end

        it "allows deleting a graded discussion", priority: "1" do
          load_agenda_view
          expect(agenda_item_title).to include_text("Graded Discussion")

          agenda_item.click
          delete_event_button.click
          click_delete_confirm_button

          expect(f("#content")).not_to contain_css(".agenda-event__item-container")
        end

        it "allows editing via modal", priority: "1" do
          test_date = 2.days.from_now
          test_name = "Test Title"
          load_agenda_view

          # Open Edit modal
          agenda_item.click
          wait_for_ajaximations
          f(".event-details .edit_event_link").click
          wait_for_ajaximations

          # Edit title and date
          replace_content(fj(".ui-dialog:visible #assignment_title"), test_name)
          due_at_field = fj(".ui-dialog:visible #assignment_due_at")
          replace_content(due_at_field, test_date.to_fs(:long))
          driver.action.send_keys(due_at_field, :return)
          f("[class='event_button btn btn-primary save_assignment']").click
          wait_for_ajaximations

          # Verify edits
          expect(agenda_item_title).to include_text(test_name)
          expect(f(".agenda-date")).to include_text(date_string(test_date, :short_with_weekday))
        end

        it "allows editing via More Options", priority: "1" do
          skip("final load_agenda_view is fragile, needs analysis")
          test_date = 2.days.from_now.change(hours: 13, min: 59, sec: 0, usec: 0)
          test_title = "Test Title"
          test_description = "New Description"
          load_agenda_view

          # Open More Options window
          agenda_item.click
          wait_for_ajaximations
          calendar_edit_event_link.click
          wait_for_ajaximations
          f(".event_button").click
          wait_for_ajaximations

          # Edit title, description, and date
          replace_content(f("#discussion-title.input-block-level"), test_title + "1")
          driver.execute_script "tinyMCE.activeEditor.setContent('#{test_description}')"
          replace_content(f(".DueDateInput"), format_time_for_view(test_date))
          f(".form-actions.flush .btn.btn-primary").click
          wait_for_ajaximations

          # Verify edited title, description, and date
          load_agenda_view
          expect(all_agenda_items).to have_size(1)
          agenda_item.click
          wait_for_ajaximations
          expect(f(".view_event_link")).to include_text(test_title)
          expect(f(".event-detail-overflow")).to include_text(test_description)
          expect(f(".event-details-timestring")).to include_text(format_time_for_view(test_date))
        end
      end

      it "shows all appointment groups" do
        create_appointment_group(contexts: [@course])
        create_appointment_group(contexts: [@course])

        get "/calendar2#view_name=agenda&view_start=#{(Time.zone.today + 1.day).strftime}"
        wait_for_ajaximations
        expect(all_agenda_items.count).to equal(2)
      end
    end
  end

  context "as a student" do
    before do
      course_with_teacher(active_all: true, name: "teacher@example.com")
      course_with_student_logged_in
    end

    it "student can not delete events created by a teacher", priority: "1" do
      # create an event as the teacher
      @course.calendar_events.create!(title: "Monkey Island", start_at: Time.zone.now.advance(days: 4))

      # browse to the view as a student
      load_agenda_view

      # click on the event and rxpect there not to be a delete button
      agenda_item.click
      expect(f("#content")).not_to contain_css(".event-details .delete_event_link")
    end

    it "displays agenda events" do
      load_agenda_view
      expect(fj(".agenda-wrapper:visible")).to be_present
    end

    context "agenda view" do
      before do
        account = Account.default
        account.settings[:agenda_view] = true
        account.save!

        create_appointment_group(contexts: [@course])
        create_appointment_group(contexts: [@course])
      end

      it "shows all options when in find appointment mode" do
        get "/calendar2#view_name=agenda&view_start=#{(Time.zone.today + 1.day).strftime}"
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css(".agenda-event__item")
        find_appointment_button.click
        f('[role="dialog"][aria-label="Select Course"] button[type="submit"]').click
        expect(all_agenda_items.count).to equal(2)
      end

      it "shows only the reserved option when not in find appointment mode" do
        get "/calendar2#view_name=agenda&view_start=#{(Time.zone.today + 1.day).strftime}"
        wait_for_ajaximations
        find_appointment_button.click
        f('[role="dialog"][aria-label="Select Course"] button[type="submit"]').click
        wait_for_ajaximations
        agenda_item.click
        f(".reserve_event_link").click
        wait_for_ajaximations
        find_appointment_button.click
        expect(all_agenda_items.count).to equal(1)
        expect(agenda_item).to include_text "Reserved"
      end
    end
  end
end
