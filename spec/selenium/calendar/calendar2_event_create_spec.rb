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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:each) do
    Account.default.tap do |a|
      a.settings[:show_scheduler]   = true
      a.save!
    end
  end

  context "as a teacher" do
    before(:each) do
      course_with_teacher_logged_in
    end
    context "event creation" do
      it "should create an event by hitting the '+' in the top bar" do
        event_title = 'new event'
        get "/calendar2"

        fj('#create_new_event_link').click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
      end

      it "should create an event with a location name" do
        event_name = 'event with location'
        create_middle_day_event(event_name, false, true)
        fj('.fc-event:visible').click
        expect(fj('.event-details-content:visible')).to include_text('location title')
      end

      it 'should create an event with name and address' do
        get "/calendar2"
        event_title = 'event title'
        location_name = 'my house'
        location_address = '555 test street'
        find_middle_day.click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        expect(title).to be_displayed
        replace_content(title, event_title)
        expect_new_page_load { f('.more_options_link').click }
        expect(driver.current_url).to match /start_date=\d\d\d\d-\d\d-\d\d/  # passed in ISO format, not localized
        expect(f('.title')).to have_value event_title
        expect(f('#editCalendarEventFull .btn-primary').text).to eq "Create Event"
        replace_content(f('#calendar_event_location_name'), location_name)
        replace_content(f('#calendar_event_location_address'), location_address)
        # submit_form makes the spec fragile
        f('#editCalendarEventFull').submit
        expect(CalendarEvent.last.location_name).to eq location_name
        expect(CalendarEvent.last.location_address).to eq location_address
      end

      it 'should cosistently format date <input> value to what datepicker would set it as, even in langs that have funky formatting' do
        skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
        skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
        @user.locale = 'fr'
        @user.save!

        get "/calendar2#view_name=month&view_start=2018-02-01"
        f('.fc-day[data-date="2018-03-02"]').click

        # verify it shows up right from the start
        expect(f('.ui-dialog #calendar_event_date').attribute(:value)).to eq('02/03/2018')
        expect(fj('.date_field_container:has(#calendar_event_date) .datetime_suggest').text).to eq 'ven. 2 Mar 2018'

        # verify it shows up right when set from the datepicker
        f('#calendar_event_date + .ui-datepicker-trigger').click
        fj('.ui-datepicker-current-day a:contains(2)').click()
        expect(f('.ui-dialog #calendar_event_date').attribute(:value)).to eq('ven 2 Mars 2018')
        expect(fj('.date_field_container:has(#calendar_event_date) .datetime_suggest').text).to eq 'ven. 2 Mar 2018'

        f('#edit_calendar_event_form button[type="submit"]').click
        expect(CalendarEvent.last.start_at).to eq Time.utc(2018, 3, 2)
      end

      it "should go to calendar event modal when a syllabus link is clicked", priority: "1", test_id: 186581 do
        event_title = "Test Event"
        make_event(title: event_title, context: @course)

        # Verifies we are taken to the event in Calendar after clicking on it in Syllabus
        get "/courses/#{@course.id}/assignments/syllabus"
        fj("a:contains('#{event_title}')").click
        wait_for_ajaximations

        expect(fj('.event-details-header:visible')).to be_displayed
        expect(f('.view_event_link')).to include_text(event_title)
      end

      it "should be able to create an event for a group" do
        group(:context => @course)

        get "/groups/#{@group.id}"
        expect_new_page_load { f('.event-list-view-calendar').click }
        event_name = 'some name'
        create_calendar_event(event_name, false, false, false)

        event = @group.calendar_events.last
        expect(event.title).to eq event_name
      end

      it "should create an event that is recurring", priority: "1", test_id: 223510 do
        Account.default.enable_feature!(:recurring_calendar_events)
        make_full_screen
        get '/calendar2'
        expect(f('#context-list li:nth-of-type(1)').text).to include(@teacher.name)
        expect(f('#context-list li:nth-of-type(2)').text).to include(@course.name)
        f('.calendar .fc-week .fc-today').click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        replace_content(title, "Test Event")
        replace_content(f("input[type=text][name= 'start_time']"), "6:00am")
        replace_content(f("input[type=text][name= 'end_time']"), "6:00pm")
        click_option(f('.context_id'), @course.name)
        expect_new_page_load { f('.more_options_link').click }
        wait_for_tiny(f(".mce-edit-area"))
        expect(f('.title')).to have_value "Test Event"
        move_to_click('#duplicate_event')
        replace_content(f("input[type=number][name='duplicate_count']"), 2)
        expect_new_page_load { f('#editCalendarEventFull').submit }
        expect(CalendarEvent.count).to eq(3)
        repeat_event = CalendarEvent.where(title: "Test Event")
        first_start_date = repeat_event[0].start_at.to_date
        expect(repeat_event[1].start_at.to_date).to eq(first_start_date + 1.week)
        expect(repeat_event[2].start_at.to_date).to eq(first_start_date + 2.weeks)
      end

      it "should create recurring section-specific events" do
        Account.default.enable_feature!(:recurring_calendar_events)
        section1 = @course.course_sections.first
        section2 = @course.course_sections.create!(:name => "other section")

        day1 = 1.day.from_now.to_date
        day2 = 2.days.from_now.to_date

        get '/calendar2'
        fj('.calendar .fc-week .fc-today').click
        edit_event_dialog = f('#edit_event_tabs')
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        replace_content(title, "Test Event")
        click_option(f('.context_id'), @course.name)
        expect_new_page_load { f('.more_options_link').click }

        # tiny can steal focus from one of the date inputs when it initializes
        wait_for_tiny(f('#calendar-description'))

        f('#use_section_dates').click

        f("#section_#{section1.id}_start_date").send_keys(day1.to_s)
        f("#section_#{section2.id}_start_date").send_keys(day2.to_s)

        ff(".date_start_end_row input.start_time").select(&:displayed?).each do |input|
          replace_content(input, "11:30am")
        end
        ff(".date_start_end_row input.end_time").select(&:displayed?).each do |input|
          replace_content(input, "1pm")
        end

        f('#duplicate_event').click
        replace_content(f("input[type=number][name='duplicate_count']"), 1)

        form = f('#editCalendarEventFull')
        expect_new_page_load{form.submit}

        expect(CalendarEvent.count).to eq(6) # 2 parent events each with 2 child events
        s1_events = CalendarEvent.where(:context_code => section1.asset_string).
          where.not(:parent_calendar_event_id => nil).order(:start_at).to_a
        expect(s1_events[1].start_at.to_date).to eq (s1_events[0].start_at.to_date + 1.week)

        s2_events = CalendarEvent.where(:context_code => section2.asset_string).
          where.not(:parent_calendar_event_id => nil).order(:start_at).to_a
        expect(s2_events[1].start_at.to_date).to eq (s2_events[0].start_at.to_date + 1.week)
      end

      it "should query for all the sections in a course when creating an event" do
        15.times.with_index { |i| add_section("Section #{i}") }

        num_sections = @course.course_sections.count

        get "/courses/#{@course.id}/calendar_events/new"
        wait_for_ajaximations
        wait_for_tiny(f(".mce-edit-area"))
        f('#use_section_dates').click

        num_rows = ff(".show_if_using_sections .row_header").length
        expect(num_rows).to be_equal(num_sections)
      end
    end
  end

  context "to-do dates" do
    before :once do
      Account.default.enable_feature!(:student_planner)
      @course = Course.create!(name: "Course 1")
      @course.offer!
      @student1 = User.create!(name: 'Student 1')
      @course.enroll_student(@student1).accept!
    end

    before(:each) do
      user_session(@student1)
    end

    context "student to-do event" do
      before :once do
        @todo_date = Time.zone.now
        @student_to_do = @student1.planner_notes.create!(todo_date: @todo_date, title: "Student to do")
      end

      it "shows student to-do events in the calendar", priority: "1", test_id: 3357313 do
        get "/calendar2"
        expect(f('.fc-content .fc-title')).to include_text(@student_to_do.title)
      end

      it "shows the correct date and context for student to-do item in calendar", priority: "1", test_id: 3357315 do
        get "/calendar2"
        f('.fc-content .fc-title').click
        event_content = fj('.event-details-content:visible')
        expect(event_content.find_element(:css, '.event-details-timestring').text).
          to eq format_time_for_view(@todo_date, :short)
        expect(event_content).to contain_link('Student 1')
      end
    end

    context "course to-do event" do
      before :once do
        @todo_date = Time.zone.now
        @course_to_do = @student1.planner_notes.create!(todo_date: @todo_date, title: "Course to do",
                                                        course_id: @course.id)
      end

      it "shows course to do events in the calendar", priority: "1", test_id: 3357314 do
        get "/calendar2"
        expect(f('.fc-content .fc-title')).to include_text(@course_to_do.title)
      end

      it "shows the correct date and context for courseto-do item in calendar", priority: "1", test_id: 3357316 do
        get "/calendar2"
        f('.fc-content .fc-title').click
        event_content = fj('.event-details-content:visible')
        expect(event_content.find_element(:css, '.event-details-timestring').text).
          to eq format_time_for_view(@todo_date, :short)
        expect(event_content).to contain_link('Course 1')
      end
    end

    context "edit to-do event" do
      before :once do
        @todo_date = Time.zone.now
        @to_do = @student1.planner_notes.create!(todo_date: @todo_date, title: "A new to do")
      end

      it "respects the calendars checkboxes" do
        make_full_screen
        get "/calendar2"
        expect(ff('.fc-view-container .fc-content .fc-title').length).to equal(1)

        # turn it off
        f("span.group_user_#{@student1.id}").click
        expect(f('.fc-view-container')).not_to contain_css('.fc-content .fc-title')
        # turn it back on
        f("span.group_user_#{@student1.id}").click
        expect(ff('.fc-view-container .fc-content .fc-title').length).to equal(1)


        # click to edit
        f(".fc-event-container a.group_user_#{@student1.id}").click
        # detial popup is displayed
        expect(f('.event-details .event-details-header h2')).to include_text(@to_do.title)
        # click edit button
        f("button.event_button.edit_event_link").click
        expect(f('#planner_note_context')).to be_displayed
        # change the calendar
        click_option('#planner_note_context', @course.name)
        # save
        f('#edit_planner_note_form_holder button[type="submit"]').click
        wait_for_ajaximations
        expect(ff('.fc-view-container .fc-content .fc-title').length).to equal(1)

        # turn it off
        f("span.group_course_#{@course.id}").click
        expect(f('.fc-view-container')).not_to contain_css('.fc-content .fc-title')
        # turn it back on
        f("span.group_course_#{@course.id}").click
        expect(ff('.fc-view-container .fc-content .fc-title').length).to equal(1)
      end

      it "edits the event in calendar", priority: "1", test_id: 3415211 do
        get "/calendar2"
        f('.fc-content .fc-title').click
        f('.edit_event_link').click
        replace_content(f('input[name=title]'), 'new to-do edited')
        datetime = @todo_date
        datetime = if datetime.to_date().mday() == '15'
                      datetime.change({day: 20})
                   else
                      datetime.change({day: 15})
                   end
        replace_content(f('input[name=date]'), format_date_for_view(datetime, :short))
        f('.validated-form-view').submit
        refresh_page
        f('.fc-content .fc-title').click
        event_content = fj('.event-details-content:visible')
        expect(event_content.find_element(:css, '.event-details-timestring').text).
          to eq format_time_for_view(datetime, :short)
        @to_do.reload
        expect(format_time_for_view(@to_do.todo_date, :short)).to eq(format_time_for_view(datetime, :short))
      end
    end
  end
end
