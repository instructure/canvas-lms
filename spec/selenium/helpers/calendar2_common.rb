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

module Calendar2Common
  def create_course_assignment
    Assignment.new.tap do |a|
      a.id = 1
      a.title = "test assignment"
      a.due_at = Time.now.utc.strftime("%Y-%m-%d 21:00:00")
      a.workflow_state = "published"
      a.context_id = @course.id
      a.context_type = "Course"
      a.save!
    end
  end

  def create_course_event
    CalendarEvent.new.tap do |c|
      c.id = 1
      c.title = "test event"
      c.start_at = Time.now.utc.strftime("%Y-%m-%d 21:00:00")
      c.workflow_state = "active"
      c.context_id = @course.id
      c.context_type = "Course"
      c.save!
    end
  end

  def create_appointment_group(params = {})
    tomorrow = (Time.now.utc.to_date + 1.day).to_s
    default_params = {
      title: "new appointment group",
      contexts: [@course],
      new_appointments: [[tomorrow + " 12:00:00", tomorrow + " 13:00:00"]]
    }
    ag = AppointmentGroup.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def create_appointment_group_early(params = {})
    tomorrow = (Time.now.utc.to_date + 1.day).to_s
    default_params = {
      title: "new appointment group",
      contexts: [@course],
      new_appointments: [[tomorrow + " 7:00", tomorrow + " 11:00:00"]]
    }
    ag = AppointmentGroup.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def create_calendar_event_series(
    context,
    title,
    start_at,
    duration = 1.hour,
    rrule = "FREQ=DAILY;INTERVAL=1;COUNT=3"
  )
    rr = RRule::Rule.new(rrule, dtstart: start_at, tzid: Time.zone.tzinfo.name)
    event_attributes = { title:, rrule:, series_uuid: SecureRandom.uuid }
    dtstart_list = rr.all
    dtstart_list.each_with_index do |dtstart, i|
      event_attributes["start_at"] = dtstart.iso8601
      event_attributes["end_at"] = (dtstart + duration).iso8601
      event_attributes["context_code"] = context.asset_string
      event = context.calendar_events.build(event_attributes)
      event.series_head = true if i == 0
      event.updating_user = @teacher
      event.save!
    end
  end

  def open_edit_event_dialog
    f(".fc-event").click
    expect(calendar_edit_event_link).to be_displayed
    calendar_edit_event_link.click
    wait_for_ajaximations
  end

  def make_event(params = {})
    opts =
      { context: @user, start: Time.zone.now, description: "Test event" }.with_indifferent_access
                                                                         .merge(params)
    c =
      CalendarEvent.new description: opts[:description],
                        start_at: opts[:start],
                        end_at: opts[:end],
                        title: opts[:title],
                        location_name: opts[:location_name],
                        location_address: opts[:location_address],
                        all_day: opts[:all_day]
    c.context = opts[:context]
    c.save!
    c
  end

  def create_quiz
    due_at = 5.minutes.from_now
    unlock_at = Time.zone.now.advance(days: -2)
    lock_at = Time.zone.now.advance(days: 4)
    title = "Test Quiz"
    @context = @course
    @quiz = quiz_model
    @quiz.generate_quiz_data
    @quiz.due_at = due_at
    @quiz.lock_at = lock_at
    @quiz.unlock_at = unlock_at
    @quiz.title = title
    @quiz.save!
    @quiz
  end

  def create_graded_discussion
    @assignment =
      @course.assignments.create!(
        title: "assignment",
        points_possible: 10,
        due_at: 5.minutes.from_now,
        submission_types: "online_text_entry",
        only_visible_to_overrides: true
      )
    @gd = @course.discussion_topics.create!(title: "Graded Discussion", assignment: @assignment)
  end

  def find_middle_day
    fj(".calendar .fc-week:nth-child(1) .fc-wed:first")
  end

  def change_calendar(direction = :next)
    css_selector =
      case direction
      when :next
        ".navigate_next"
      when :prev
        ".navigate_prev"
      when :today
        ".navigate_today"
      else
        raise "unrecognized direction #{direction}"
      end

    f(".calendar_header " + css_selector).click
    wait_for_ajaximations
  end

  def quick_jump_to_date(text)
    f(".navigation_title").click
    date_input = f(".date_field")
    date_input.send_keys(text + "\n")
    wait_for_ajaximations
  end

  # updated this to type in a date instead of picking it from the calendar
  def add_date(middle_number)
    replace_content(f("input[type=text][id=calendar_event_date]"), middle_number)
  end

  def create_assignment_event(
    assignment_title,
    should_add_date: false,
    publish: false,
    date: nil,
    use_current_course_calendar: false
  )
    middle_number = find_middle_day["data-date"]
    find_middle_day.click
    edit_event_dialog = f("#edit_event_tabs")
    expect(edit_event_dialog).to be_displayed
    edit_event_dialog.find(".edit_assignment_option").click
    edit_assignment_form = edit_event_dialog.find("#edit_assignment_form")
    title = edit_assignment_form.find("#assignment_title")
    keep_trying_until { title.displayed? }
    replace_content(title, assignment_title)
    click_option(".context_id", @course.name) if use_current_course_calendar
    date = middle_number if date.nil?
    add_date(date) if should_add_date
    move_to_click("label[for=assignment_published]") if publish
    submit_form(edit_assignment_form)
    expect(f(".fc-month-view .fc-event:not(.event_pending) .fc-title")).to include_text(
      assignment_title
    )
  end

  # Creates event from clicking on the mini calendar
  def create_calendar_event(
    event_title,
    should_add_date: false,
    should_add_location: false,
    should_duplicate: false,
    date: nil,
    use_current_course_calendar: false
  )
    middle_number = find_middle_day["data-date"]
    find_middle_day.click
    edit_event_dialog = f("#edit_event_tabs")
    expect(edit_event_dialog).to be_displayed
    title = edit_calendar_event_form_title
    keep_trying_until { title.displayed? }
    replace_content(title, event_title)
    click_option(edit_calendar_event_form_context, @course.name) if use_current_course_calendar
    date = middle_number if date.nil?
    add_date(date) if should_add_date
    if should_add_location
      replace_content(f("input[placeHolder='Input Event Location...'"), "location title")
    end

    if should_duplicate
      f("#duplicate_event").click
      duplicate_options = edit_calendar_event_form.find("#duplicate_interval")
      keep_trying_until { duplicate_options.displayed? }
      duplicate_interval = edit_calendar_event_form.find("#duplicate_interval")
      duplicate_count = edit_calendar_event_form.find("#duplicate_count")
      replace_content(duplicate_interval, "1")
      replace_content(duplicate_count, "3")
      f("#append_iterator").click
    end

    submit_form(edit_calendar_event_form)
    wait_for_ajax_requests
    if should_duplicate
      4.times do |i|
        expect(ff(".fc-month-view .fc-title")[i]).to include_text("#{event_title} #{i + 1}")
      end
    else
      expect(f(".fc-month-view .fc-title")).to include_text(event_title)
    end
  end

  def input_timed_calendar_event_fields(new_date, start_time, end_time)
    get "/calendar2"
    find_middle_day.click
    replace_content(edit_calendar_event_form_title, "Timed Event")
    replace_content(edit_calendar_event_form_date, format_date_for_view(new_date, :medium))
    edit_calendar_event_start_input.click
    replace_content(edit_calendar_event_start_input, start_time)
    edit_calendar_event_start_input.send_keys :return
    edit_calendar_event_end_input.click
    replace_content(edit_calendar_event_end_input, end_time)
    edit_calendar_event_end_input.send_keys :return
  end

  def create_timed_calendar_event(new_date, start_time, end_time)
    input_timed_calendar_event_fields(new_date, start_time, end_time)
    edit_calendar_event_form_submit_button.click
    wait_for_ajaximations
    refresh_page
  end

  def time_to_lower(time_string)
    time_string.gsub(/\s+/, "").gsub(":00", "").downcase
  end

  def test_timed_calendar_event_in_tz(time_zone, start_time = "6:30 AM", end_time = "6:30 PM")
    puts ">>> TZ #{time_zone}, #{Time.zone}"
    @user.time_zone = time_zone
    @user.save!
    @date = @user.time_zone.now.beginning_of_day
    new_date = @date
    new_date =
      (new_date.to_date.mday == "15") ? new_date.change({ day: 20 }) : new_date.change({ day: 15 })
    create_timed_calendar_event(new_date, start_time, end_time)
    event_title_on_calendar.click
    expect(
      event_content.find_element(:css, ".event-details-timestring").text
    ).to eq "#{format_date_for_view(new_date, "%b %d")}, #{time_to_lower(start_time)} - #{time_to_lower(end_time)}"

    calendar_edit_event_link.click
    edit_calendar_event_form_submit_button.click
    wait_for_ajaximations
    refresh_page
    event_title_on_calendar.click
    expect(
      event_content.find_element(:css, ".event-details-timestring").text
    ).to eq "#{format_date_for_view(new_date, "%b %d")}, #{time_to_lower(start_time)} - #{time_to_lower(end_time)}"
  end

  def test_timed_calendar_event_in_tz_more_options(
    time_zone,
    start_time = "6:30 AM",
    end_time = "6:30 PM"
  )
    @user.time_zone = time_zone
    @user.save!
    @date = @user.time_zone.now.beginning_of_day
    new_date = @date
    new_date =
      (new_date.to_date.mday == "15") ? new_date.change({ day: 20 }) : new_date.change({ day: 15 })
    input_timed_calendar_event_fields(new_date, start_time, end_time)
    expect_new_page_load { edit_calendar_event_form_more_options.click }
    expect(more_options_date_field.property("value")).to eq(
      format_date_for_view(new_date, :medium)
    )
    expect(more_options_start_time_field.property("value")).to eq(start_time)
    expect(more_options_end_time_field.property("value")).to eq(end_time)

    more_options_submit_button.click
    wait_for_ajaximations
    refresh_page
    event_title_on_calendar.click
    expect(
      event_content.find_element(:css, ".event-details-timestring").text
    ).to eq "#{format_date_for_view(new_date, "%b %d")}, #{time_to_lower(start_time)} - #{time_to_lower(end_time)}"
  end

  # Creates event from the 'edit event' modal
  def event_from_modal(event_title, should_add_date = false, should_add_location = false)
    edit_event_dialog = f("#edit_event_tabs")
    expect(edit_event_dialog).to be_displayed
    title = edit_calendar_event_form_title
    keep_trying_until { title.displayed? }
    replace_content(title, event_title)
    add_date(middle_number) if should_add_date
    if should_add_location
      replace_content(f("input[placeHolder='Input Event Location...'"), "location title")
    end
    edit_calendar_event_form_submit_button.click
    wait_for_ajax_requests
  end

  def header_text
    header = f(".calendar_header .navigation_title")
    header.text
  end

  def create_middle_day_event(
    name = "new event",
    with_date: false,
    with_location: false,
    with_duplicates: false,
    date: nil,
    use_current_course_calendar: false
  )
    get "/calendar2"
    create_calendar_event(
      name,
      should_add_date: with_date,
      should_add_location: with_location,
      should_duplicate: with_duplicates,
      date:,
      use_current_course_calendar:
    )
  end

  def create_middle_day_assignment(name = "new assignment")
    get "/calendar2"
    create_assignment_event(name)
  end

  def create_published_middle_day_assignment
    get "/calendar2"
    create_assignment_event("new assignment", publish: true)
  end

  def load_week_view
    get "/calendar2"
    f("#week").click
  end

  def load_month_view
    get "/calendar2"
    f("#month").click
    wait_for_ajaximations
  end

  def load_agenda_view
    get "/calendar2"
    f("#agenda").click
    wait_for_ajaximations
  end

  # This checks the date in the edit modal, since Week View and Month view events are placed via absolute
  # positioning and there is no other way to verify the elements are on the right date
  def assert_edit_modal_date(due_at)
    scroll_to(f(".fc-event"))
    f(".fc-event").click

    max_attempts = 8
    num_attempts = 1

    until element_exists?(".event-details-timestring") || num_attempts == max_attempts
      puts "Attempt #{num_attempts} looking for event element"
      scroll_to(f(".fc-event"))
      f(".fc-event").click
      num_attempts += 1
    end
    expect(f(".event-details-timestring")).to include_text(format_date_for_view(due_at))
  end

  def assert_title(title, agenda_view)
    if agenda_view
      expect(f(".agenda-event__title")).to include_text(title)
    else
      expect(f(".fc-title")).to include_text(title)
    end
  end

  # The following methods verify that created events of all kinds are present in each view and have correct dates
  def assert_agenda_view(title, due)
    load_agenda_view
    assert_title(title, true)
    expect(f(".navigation_title")).to include_text(format_date_for_view(due))
  end

  def assert_week_view(title, due)
    load_week_view
    assert_title(title, false)
    assert_edit_modal_date(due)
  end

  def assert_month_view(title, due)
    load_month_view
    assert_title(title, false)
    assert_edit_modal_date(due)
  end

  def assert_views(title, due)
    assert_agenda_view(title, due)
    assert_week_view(title, due)
    assert_month_view(title, due)
  end

  def edit_new_event_in_more_options_page(context_name = nil)
    calendar_create_event_button.click
    replace_content(edit_calendar_event_form_title, "blackout event")
    click_option(edit_calendar_event_form_context, context_name) unless context_name.nil?
    expect_new_page_load { edit_calendar_event_form_more_options.click }
  end

  def check_more_options_blackout_date_and_submit
    more_options_blackout_date_checkbox.click
    edit_calendar_event_form_submit_button.click
    wait_for_ajaximations
  end

  def create_blackout_date_through_more_options_page(context_name)
    edit_new_event_in_more_options_page(context_name)
    check_more_options_blackout_date_and_submit
  end

  def edit_calendar_event_in_more_options_page
    event_title_on_calendar.click
    calendar_edit_event_link.click
    expect_new_page_load { edit_calendar_event_form_more_options.click }
  end

  def enable_course_account_calendar
    @course.account.account_calendar_visible = true
    @course.account.save!
    account_admin_user(account: @course.account)
    user_session(@admin)
    get "/calendar2"
    add_other_calendars_button.click
    # because clicking the checkbox clicks on a sibling span
    click_account_calendar_modal_checkbox
    click_account_calendar_modal_save_button.click
    calendar_flash_alert_message_button.click
  end

  def event_title_on_calendar
    f(".fc-content .fc-title")
  end

  def calendar_edit_event_link
    f(".edit_event_link")
  end

  def calendar_create_event_button
    f("#create_new_event_link")
  end

  def agenda_item
    f(".agenda-event__item-container")
  end

  def all_agenda_items
    ff(".agenda-event__item-container")
  end

  def delete_event_button
    f(".event-details .delete_event_link")
  end

  def agenda_view_header
    f(".navigation_title")
  end

  def agenda_item_title
    f(".agenda-event__title")
  end

  def find_appointment_button
    f("#FindAppointmentButton")
  end

  def appointment_group_tab_button
    f(".edit_appointment_group_option")
  end

  # return the parent of the <input> since you can't click the input
  def event_series_this_event
    f("[name='which'][value='one']").find_element(xpath: "./..")
  end

  def event_series_following_events
    f("[name='which'][value='following']").find_element(xpath: "./..")
  end

  def event_series_all_events
    f("[name='which'][value='all']").find_element(xpath: "./..")
  end

  def event_series_delete_button
    fj('button:contains("Delete")')
  end

  def edit_calendar_event_form
    f("[data-testid='calendar-event-form']")
  end

  def edit_calendar_event_form_title
    f("[placeHolder='Input Event Title...']")
  end

  def edit_calendar_event_form_context
    f("[data-testid='edit-calendar-event-form-context']")
  end

  def edit_calendar_event_form_date
    f("input[data-testid='edit-calendar-event-form-date']")
  end

  def edit_calendar_event_start_input
    f("[data-testid='event-form-start-time']")
  end

  def edit_calendar_event_end_input
    f("[data-testid='event-form-end-time']")
  end

  def edit_calendar_event_important_date_checkbox
    f("label[for='k5-field'] div")
  end

  def edit_calendar_event_form_blackout_date_checkbox_selector
    "label[for='course-pacing-field'] div"
  end

  def edit_calendar_event_form_blackout_date_checkbox
    f(edit_calendar_event_form_blackout_date_checkbox_selector)
  end

  def more_options_calendar_event_is_blackout_date
    more_options_blackout_date_checkbox.attribute("checked")
  end

  def calendar_event_is_blackout_date
    f("label[for='course-pacing-field'] input").attribute("checked")
  end

  def edit_calendar_event_form_more_options
    f("button[data-testid='edit-calendar-event-more-options-button']")
  end

  def edit_calendar_event_form_submit_button
    f("button[type='submit']")
  end

  def more_options_title_field
    f("#calendar_event_title")
  end

  def more_options_date_field
    f("#calendar_event_date")
  end

  def more_options_start_time_field
    f("input[placeHolder='Start Time']")
  end

  def more_options_end_time_field
    f("input[placeHolder='End Time']")
  end

  def more_options_blackout_date_checkbox
    f("#calendar_event_blackout_date")
  end

  def more_options_submit_button
    f("button[type='submit']")
  end

  def more_options_error_box
    f(".errorBox:not(#error_box_template)")
  end

  def event_content
    fj(".event-details-content:visible")
  end

  def add_other_calendars_button
    f("button[data-testid='add-other-calendars-button']")
  end

  def click_account_calendar_modal_checkbox
    driver.execute_script("$('input[data-testid=account-#{@course.account.id}-checkbox]').click()")
  end

  def click_account_calendar_modal_save_button
    f("button[data-testid='save-calendars-button']")
  end

  def calendar_flash_alert_message_button
    f(".flashalert-message button")
  end

  def context_selector_button
    f(".select-calendar-container .ag_contexts_selector")
  end

  def context_checkbox(course_id)
    f(".ag-contexts input[id='option_course_#{course_id}']")
  end

  def close_context_selector_button
    f(".ag_contexts_done")
  end

  def select_context_in_context_selector(course_id)
    context_selector_button.click
    context_checkbox(course_id).click
    close_context_selector_button.click
  end

  def allow_observer_signup_checkbox
    f("#observer-signup-option")
  end
end
