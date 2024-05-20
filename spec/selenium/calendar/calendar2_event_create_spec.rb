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
require_relative "../../helpers/k5_common"
require_relative "pages/calendar_page"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include K5Common
  include CalendarPage

  before(:once) do
    Account
      .find_or_create_by!(id: 0)
      .update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
  end

  before do
    Account.default.tap do |a|
      a.settings[:show_scheduler] = true
      a.save!
    end
  end

  context "as a teacher" do
    before { course_with_teacher_logged_in }

    context "event creation" do
      it "creates an event by hitting the '+' in the top bar" do
        get "/calendar2"

        f("#create_new_event_link").click
        edit_event_dialog = f("#edit_event_tabs")
        expect(edit_event_dialog).to be_displayed
      end

      it "displays a flash alert if no calendar is selected when trying to create an event" do
        @user.set_preference(:selected_calendar_contexts, [])
        get "/calendar2"
        wait_for_ajaximations

        f("#create_new_event_link").click
        flash_holder = f(".flashalert-message")
        expect(flash_holder.text).to include("You must select at least one calendar to create an event.")
      end

      it "creates an event with a location name" do
        event_name = "event with location"
        create_middle_day_event(event_name, with_location: true)
        fj(".fc-event:visible").click
        expect(fj(".event-details-content:visible")).to include_text("location title")
      end

      it "creates an event with name and address" do
        get "/calendar2"
        event_title = "event title"
        location_name = "my house"
        location_address = "555 test street"
        find_middle_day.click
        edit_event_dialog = f("#edit_event_tabs")
        expect(edit_event_dialog).to be_displayed
        title = edit_calendar_event_form_title
        expect(title).to be_displayed
        replace_content(title, event_title)
        expect_new_page_load { edit_calendar_event_form_more_options.click }
        expect(driver.current_url).to match(/start_date=\d\d\d\d-\d\d-\d\d/) # passed in ISO format, not localized
        expect(f(".title")).to have_value event_title
        expect(f("#editCalendarEventFull .btn-primary").text).to eq "Create Event"
        replace_content(f("#calendar_event_location_name"), location_name)
        replace_content(f("#calendar_event_location_address"), location_address)

        # submit_form makes the spec fragile
        wait_for_new_page_load { f("#editCalendarEventFull").submit }
        expect(CalendarEvent.last.location_name).to eq location_name
        expect(CalendarEvent.last.location_address).to eq location_address
      end

      it "consistently formats date <input> value to what datepicker would set it as, even in langs that have funky formatting" do
        skip("USE_OPTIMIZED_JS=true") unless ENV["USE_OPTIMIZED_JS"]
        skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
        @user.locale = "fr"
        @user.save!

        get "/calendar2#view_name=month&view_start=2018-02-01"
        f('.fc-day[data-date="2018-03-02"]').click

        # verify it shows up right from the start
        expect(f(".ui-dialog #calendar_event_date").attribute(:value)).to eq("02/03/2018")
        expect(
          fj(".date_field_container:has(#calendar_event_date) .datetime_suggest").text
        ).to eq "ven. 2 Mar 2018"

        # verify it shows up right when set from the datepicker
        f("#calendar_event_date + .ui-datepicker-trigger").click
        fj(".ui-datepicker-current-day a:contains(2)").click
        expect(f(".ui-dialog #calendar_event_date").attribute(:value)).to eq("ven 2 Mars 2018")
        expect(
          fj(".date_field_container:has(#calendar_event_date) .datetime_suggest").text
        ).to eq "ven. 2 Mar 2018"

        f('#edit_calendar_event_form button[type="submit"]').click
        expect(CalendarEvent.last.start_at).to eq Time.utc(2018, 3, 2)
      end

      it "goes to calendar event modal when a syllabus link is clicked", priority: "1" do
        event_title = "Test Event"
        make_event(title: event_title, context: @course)

        # Verifies we are taken to the event in Calendar after clicking on it in Syllabus
        get "/courses/#{@course.id}/assignments/syllabus"
        fj("a:contains('#{event_title}')").click
        wait_for_ajaximations

        expect(fj(".event-details-header:visible")).to be_displayed
        expect(f(".view_event_link")).to include_text(event_title)
      end

      it "is able to create an event for a group" do
        group(context: @course)

        get "/groups/#{@group.id}"
        expect_new_page_load { f(".event-list-view-calendar").click }
        event_name = "some name"
        create_calendar_event(event_name)

        event = @group.calendar_events.last
        expect(event.title).to eq event_name
      end

      it "is not able to create an event without a title in edit event view" do
        get "/courses/#{@course.id}/calendar_events/new"
        wait_for_tiny(f("iframe", f(".ic-RichContentEditor")))
        replace_content(more_options_title_field, "")
        more_options_submit_button.click
        wait_for_ajaximations

        expect(more_options_error_box).to include_text("You must enter a title")
        expect(@course.calendar_events.count).to eq(0)
      end

      it "is not able to create an event without a date in edit event view" do
        get "/courses/#{@course.id}/calendar_events/new"
        wait_for_tiny(f("iframe", f(".ic-RichContentEditor")))
        replace_content(more_options_title_field, "Test event")
        replace_content(more_options_date_field, "")

        more_options_submit_button.click
        wait_for_ajaximations

        expect(more_options_error_box).to include_text("You must enter a date")
        expect(@course.calendar_events.count).to eq(0)
      end

      it "queries for all the sections in a course when creating an event" do
        15.times { |i| add_section("Section #{i}") }

        num_sections = @course.course_sections.count

        get "/courses/#{@course.id}/calendar_events/new"
        wait_for_ajaximations
        wait_for_tiny(f("iframe", f(".ic-RichContentEditor")))
        f("#use_section_dates").click

        num_rows = ff(".show_if_using_sections .row_header").length
        expect(num_rows).to equal(num_sections)
      end

      it "keeps the modal's context changes in the more options screen when editing" do
        get "/calendar2"
        wait_for_ajaximations
        calendar_create_event_button.click
        replace_content(edit_calendar_event_form_title, "Event in personal calendar")
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        expect(@user.calendar_events.last.title).to eq("Event in personal calendar")
        event_title_on_calendar.click
        calendar_edit_event_link.click
        replace_content(edit_calendar_event_form_title, "Event in course calendar")
        click_option(edit_calendar_event_form_context, @course.name)
        expect_new_page_load { edit_calendar_event_form_more_options.click }
        more_options_submit_button.click
        wait_for_ajaximations
        expect(@course.calendar_events.last.title).to eq("Event in course calendar")
      end

      it "keeps the modal's context if the context is unable to be changed in the more options screen when editing" do
        section1 = @course.course_sections.first
        CalendarEvent.create!(
          context: section1,
          title: "Section Event",
          start_at: Time.zone.now,
          end_at: 1.hour.from_now,
          effective_context_code: @course.asset_string
        )
        get "/calendar2"
        wait_for_ajaximations
        event_title_on_calendar.click
        calendar_edit_event_link.click
        expect_new_page_load { edit_calendar_event_form_more_options.click }
        expect_new_page_load { more_options_submit_button.click }
        expect(driver.current_url).to match %r{/calendar2}
      end

      it "creates an event with an important date in a k5 subject" do
        toggle_k5_setting(@course.account)

        get "/calendar2"
        wait_for_ajaximations
        calendar_create_event_button.click
        replace_content(edit_calendar_event_form_title, "important event")
        click_option(edit_calendar_event_form_context, @course.name)
        edit_calendar_event_important_date_checkbox.click
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        expect(@course.calendar_events.last.important_dates).to be_truthy
      end

      context "with account level calendars" do
        before do
          account = Account.default # or (Account.create!)
          account.account_calendar_visible = true
          account.save!
        end

        it "users can switch between an account calendar and a user calendar with the same name" do
          skip "FOO-3525 (10/6/2023)"
          @course.account.name = "nobody+1@example.com"
          @course.account.save!
          enable_course_account_calendar
          calendar_create_event_button.click
          replace_content(edit_calendar_event_form_title, "Pandamonium")
          edit_calendar_event_form_context.click
          edit_calendar_event_form_context.send_keys(:down)
          edit_calendar_event_form_context.send_keys(:return)
          edit_calendar_event_form_submit_button.click
          wait_for_ajaximations
          expect(@user.calendar_events.last).to be_nil
          expect(@course.account.calendar_events.last.title).to eq("Pandamonium")
        end
      end

      context "with course pacing" do
        before do
          Account.site_admin.enable_feature! :account_level_blackout_dates
          Account.site_admin.enable_feature! :course_paces
          @course.enable_course_paces = true
          @course.save!
        end

        after do
          Account.site_admin.disable_feature! :account_level_blackout_dates
          Account.site_admin.disable_feature! :course_paces
        end

        it "creates a blackout calendar event in when feature is enabled" do
          get "/calendar2"
          wait_for_ajaximations
          calendar_create_event_button.click
          replace_content(edit_calendar_event_form_title, "blackout event")
          click_option(edit_calendar_event_form_context, @course.name)
          edit_calendar_event_form_blackout_date_checkbox.click
          edit_calendar_event_form_submit_button.click
          wait_for_ajaximations
          event_title_on_calendar.click
          calendar_edit_event_link.click
          expect(calendar_event_is_blackout_date).to be_truthy
          edit_calendar_event_form_blackout_date_checkbox.click
          edit_calendar_event_form_submit_button.click
          wait_for_ajaximations
          event_title_on_calendar.click
          calendar_edit_event_link.click
          expect(calendar_event_is_blackout_date).to be_falsey
        end

        it "cannot create a blackout date when feature is disabled" do
          Account.site_admin.disable_feature! :account_level_blackout_dates
          get "/calendar2"
          wait_for_ajaximations
          calendar_create_event_button.click
          click_option(edit_calendar_event_form_context, @course.name)
          expect(f("body")).not_to contain_css(
            edit_calendar_event_form_blackout_date_checkbox_selector
          )
        end

        it "creates a blackout calendar event in more options screen when feature is enabled" do
          get "/calendar2"
          wait_for_ajaximations
          create_blackout_date_through_more_options_page(@course.name)
          edit_calendar_event_in_more_options_page
          expect(more_options_calendar_event_is_blackout_date).to be_truthy
          check_more_options_blackout_date_and_submit
          edit_calendar_event_in_more_options_page
          expect(more_options_calendar_event_is_blackout_date).to be_falsey
        end

        it "cannot create a blackout date in more options screen when feature is disabled" do
          Account.site_admin.disable_feature! :account_level_blackout_dates
          get "/calendar2"
          wait_for_ajaximations
          edit_new_event_in_more_options_page
          expect(f("body")).not_to contain_css("#calendar_event_blackout_date")
        end
      end

      it "can edit an all_day event in calendar", priority: "1" do
        @date = Time.zone.now.beginning_of_day
        @event = make_event(start: @date, end: @date, title: "An all day event")

        new_date = @date
        new_date =
          if new_date.to_date.mday == "15"
            new_date.change({ day: 20 })
          else
            new_date.change({ day: 15 })
          end

        get "/calendar2"
        event_title_on_calendar.click
        calendar_edit_event_link.click
        replace_content(edit_calendar_event_form_title, "An all day event edited")
        replace_content(edit_calendar_event_form_date, format_date_for_view(new_date, :medium))
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        refresh_page
        event_title_on_calendar.click
        expect(
          event_content.find_element(:css, ".event-details-timestring").text
        ).to eq format_date_for_view(new_date, "%b %d")
        @event.reload
        expect(@event.all_day).to be true
      end

      it "shows a SR alert when an event is created" do
        get "/calendar2"
        calendar_create_event_button.click
        replace_content(edit_calendar_event_form_title, "new event")
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        expect(screenreader_message_holder).to include_text("The event was successfully created")
      end

      it "can create timed events in calendar" do
        @date = Time.zone.now.beginning_of_day
        start_time = "6:30 AM"
        end_time = "6:30 PM"
        new_date = @date
        new_date =
          if new_date.to_date.mday == "15"
            new_date.change({ day: 20 })
          else
            new_date.change({ day: 15 })
          end
        create_timed_calendar_event(new_date, start_time, end_time)
        event_title_on_calendar.click
        expect(
          event_content.find_element(:css, ".event-details-timestring").text
        ).to eq "#{format_date_for_view(new_date, "%b %d")}, 6:30am - 6:30pm"
      end

      it "can edit timed events in calendar" do
        test_timed_calendar_event_in_tz("Etc/UTC")
      end

      it "can edit timed events in calendar in Denver" do
        puts ">>> testing in Denver"
        test_timed_calendar_event_in_tz("America/Denver")
      end

      it "can edit timed events in calendar in Tokyo" do
        puts ">>> testing in Tokyo"
        test_timed_calendar_event_in_tz("Asia/Tokyo")
      end

      it "can edit timed events in calendar in Hawaii" do
        test_timed_calendar_event_in_tz("Pacific/Honolulu")
      end

      it "can create timed events in calendar More Options screen" do
        test_timed_calendar_event_in_tz_more_options("Etc/UTC")
      end

      it "can create timed events in calendar More Options screen in Denver" do
        test_timed_calendar_event_in_tz_more_options("America/Denver")
      end

      it "can create timed events in calendar More Options screen in Tokyo" do
        test_timed_calendar_event_in_tz_more_options("Asia/Tokyo")
      end

      it "can create timed events in calendar More Options screen in Hawaii" do
        test_timed_calendar_event_in_tz_more_options("Pacific/Honolulu", "12:00 AM", "11:30 PM")
      end

      it "can create timed events in calendar More Options screen in Tonga" do
        test_timed_calendar_event_in_tz_more_options("Pacific/Apia", "11:00 PM", "11:30 PM")
      end

      it "lets teachers set a date for each section where they have permission" do
        section1 = @course.default_section
        section2 = @course.course_sections.create!

        limited_teacher_role = custom_teacher_role("Limited teacher", account: Account.default)
        RoleOverride.create!(
          context: Account.default,
          permission: "manage_calendar",
          role: limited_teacher_role,
          enabled: false
        )
        @course.enroll_teacher(@user, enrollment_state: :active, section: section1)
        @course.enroll_teacher(
          @user,
          role: limited_teacher_role,
          enrollment_state: :active,
          section: section2
        )
        @user.enrollments.update_all(limit_privileges_to_course_section: true)

        now = Time.zone.now.beginning_of_day
        event =
          @course.calendar_events.build title: "Today Event",
                                        child_event_data: [
                                          {
                                            start_at: now,
                                            end_at: 5.minutes.from_now(now),
                                            context_code: section1.asset_string
                                          },
                                          {
                                            start_at: 5.minutes.from_now(now),
                                            end_at: 10.minutes.from_now(now),
                                            context_code: section2.asset_string
                                          }
                                        ]
        event.updating_user = account_admin_user
        event.save!

        get "/courses/#{@course.id}/calendar_events/#{event.id}/edit"
        expect(use_section_dates_checkbox.attribute("checked")).to be_truthy
        expect(use_section_dates_checkbox.attribute("disabled")).to be_truthy
        expect(f("#section_#{section1.id}_start_date").attribute("disabled")).to be_falsey
        expect(f("#section_#{section2.id}_start_date").attribute("disabled")).to be_truthy
        expect(f("#section_#{section1.id}_start_date+button").attribute("disabled")).to be_falsey
        expect(f("#section_#{section2.id}_start_date+button").attribute("disabled")).to be_truthy

        replace_content(f("#section_#{section1.id}_start_date"), "")
        f("#editCalendarEventFull button[type=submit]").click
        wait_for_ajaximations
        wait_for_new_page_load { f(".ui-dialog .ui-dialog-buttonset .btn-primary").click }
        wait_for_ajaximations
        expect(event.reload.child_events.length).to be 1
      end

      it "preserves correct time when editing an event in a different DST window" do
        @user.time_zone = "America/Denver"
        @user.save!
        now = DateTime.current.noon
        # by creating an event at t+3, t+6, and t+9 months, we guarantee that at least 1 of those
        # events will be in a different DST state than now
        [now + 3.months, now + 6.months, now + 9.months].each do |start_at|
          end_at = start_at + 1.hour
          event = CalendarEvent.create!(context: @course, start_at:, end_at:)
          child_event = event.child_events.create!(context: @course.default_section, start_at:, end_at:)
          get "/courses/#{@course.id}/calendar_events/#{event.id}/edit"
          wait_for_new_page_load { f("#editCalendarEventFull").submit }
          expect(child_event.reload.start_at).to eq(start_at)
          expect(child_event.reload.end_at).to eq(end_at)
        end
      end

      it "updates the event to the correct time when saving across DST window" do
        @user.time_zone = "America/Denver"
        @user.save!
        start_at = DateTime.parse("2022-03-01 1:00pm -0600")
        event = CalendarEvent.create!(context: @course, start_at:)
        get "/courses/#{@course.id}/calendar_events/#{event.id}/edit"
        expect(f("#more_options_start_time").attribute(:value)).to eq("12:00pm")
        replace_content(f("[name=\"start_date\"]"), "2022-03-14")
        wait_for_new_page_load { more_options_submit_button.click }
        get "/courses/#{@course.id}/calendar_events/#{event.id}/edit"
        expect(f("#more_options_start_time").attribute(:value)).to eq("12:00pm")
      end
    end

    context "assignment creation" do
      it "uses the course default due time" do
        untitled_course = @course
        untitled_course.update(default_due_time: "17:30:00")
        course_with_teacher(user: @teacher, active_enrollment: true, course_name: "Time")
        get "/calendar2"
        wait_for_ajaximations
        calendar_create_event_button.click
        f("[aria-controls=\"edit_assignment_form_holder\"]").click
        today = untitled_course.time_zone.today
        expect(f("#assignment_due_at").attribute(:value)).to eq(
          I18n.l(today, format: :medium_with_weekday)
        )
        replace_content(f("#assignment_title"), "important assignment")
        click_option(f("#assignment_context"), untitled_course.name)
        expect(f("#assignment_due_at").attribute(:value)).to eq(
          "#{I18n.l(today, format: :medium_with_weekday)} 5:30pm"
        )
        f("#edit_assignment_form_holder button[type=submit]").click
        wait_for_ajaximations
        expect(untitled_course.assignments.last.due_at).to eq(
          today.to_time(:utc).change(hour: 17, min: 30)
        )
      end
    end
  end

  context "to-do dates" do
    before :once do
      @course = Course.create!(name: "Course 1")
      @course.offer!
      @student1 = User.create!(name: "Student 1")
      @course.enroll_student(@student1).accept!
    end

    before { user_session(@student1) }

    context "student to-do event" do
      before :once do
        @todo_date = Time.zone.now
        @student_to_do =
          @student1.planner_notes.create!(todo_date: @todo_date, title: "Student to do")
      end

      it "shows student to-do events in the calendar", priority: "1" do
        get "/calendar2"
        expect(event_title_on_calendar).to include_text(@student_to_do.title)
      end

      it "shows the correct date and context for student to-do item in calendar", priority: "1" do
        get "/calendar2"
        event_title_on_calendar.click
        expect(
          event_content.find_element(:css, ".event-details-timestring").text
        ).to eq format_time_for_view(@todo_date, :short)
        expect(event_content).to contain_link("Student 1")
      end
    end

    context "course to-do event" do
      before :once do
        @todo_date = Time.zone.now
        @course_to_do =
          @student1.planner_notes.create!(
            todo_date: @todo_date,
            title: "Course to do",
            course_id: @course.id
          )
      end

      it "shows course to do events in the calendar", priority: "1" do
        get "/calendar2"
        expect(event_title_on_calendar).to include_text(@course_to_do.title)
      end

      it "shows the correct date and context for courseto-do item in calendar", priority: "1" do
        get "/calendar2"
        event_title_on_calendar.click
        expect(
          event_content.find_element(:css, ".event-details-timestring").text
        ).to eq format_time_for_view(@todo_date, :short)
        expect(event_content).to contain_link("Course 1")
      end
    end

    context "edit to-do event" do
      before :once do
        @todo_date = Time.zone.now
        @to_do = @student1.planner_notes.create!(todo_date: @todo_date, title: "A new to do")
      end

      it "respects the calendars checkboxes" do
        get "/calendar2"
        expect(ff(".fc-view-container .fc-content .fc-title").length).to equal(1)

        # turn it off
        f("span.group_user_#{@student1.id}").click
        expect(f(".fc-view-container")).not_to contain_css(".fc-content .fc-title")

        # turn it back on
        f("span.group_user_#{@student1.id}").click
        expect(ff(".fc-view-container .fc-content .fc-title").length).to equal(1)

        # click to edit
        f(".fc-event-container a.group_user_#{@student1.id}").click

        # detial popup is displayed
        expect(f(".event-details .event-details-header h2")).to include_text(@to_do.title)

        # click edit button
        f("button.event_button.edit_event_link").click
        expect(f("#planner_note_context")).to be_displayed

        # change the calendar
        click_option("#planner_note_context", @course.name)

        # save
        f('#edit_planner_note_form_holder button[type="submit"]').click
        wait_for_ajaximations
        expect(ff(".fc-view-container .fc-content .fc-title").length).to equal(1)

        # turn it off
        f("span.group_course_#{@course.id}").click
        expect(f(".fc-view-container")).not_to contain_css(".fc-content .fc-title")

        # turn it back on
        f("span.group_course_#{@course.id}").click
        expect(ff(".fc-view-container .fc-content .fc-title").length).to equal(1)
      end

      it "edits the event in calendar", priority: "1" do
        get "/calendar2"
        event_title_on_calendar.click
        calendar_edit_event_link.click
        replace_content(f("input[name=title]"), "new to-do edited")
        datetime = @todo_date
        datetime =
          if datetime.to_date.mday == "15"
            datetime.change({ day: 20 })
          else
            datetime.change({ day: 15 })
          end
        replace_content(f("input[name=date]"), format_date_for_view(datetime, :short))
        edit_calendar_event_form_submit_button.click
        wait_for_ajaximations
        refresh_page
        event_title_on_calendar.click
        expect(
          event_content.find_element(:css, ".event-details-timestring").text
        ).to eq format_time_for_view(datetime, :short)
        @to_do.reload
        expect(format_time_for_view(@to_do.todo_date, :short)).to eq(
          format_time_for_view(datetime, :short)
        )
      end
    end
  end
end
