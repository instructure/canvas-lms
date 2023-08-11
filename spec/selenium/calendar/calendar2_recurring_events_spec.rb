# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "../helpers/calendar2_common"
require_relative "pages/calendar_page"
require_relative "pages/calendar_recurrence_modal_page"
require_relative "pages/calendar_edit_page"
require "rrule"

describe "recurring events" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include CalendarPage
  include CalendarRecurrenceModelPage
  include CalendarEditPage

  context "calendar event modal" do
    before :once do
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
    end

    it "displays the frequency picker on calendar event modal" do
      get "/calendar2"
      create_new_calendar_event
      expect(frequency_picker).to be_displayed
      expect(frequency_picker_value).to eq("Does not repeat")
    end

    it "selects the daily frequency in the calendar event modal" do
      get "/calendar2"
      create_new_calendar_event
      select_frequency_option("Daily")
      expect(frequency_picker_value).to eq("Daily")
    end

    it "selects the weekly, then weekdays frequency in the calendar event modal" do
      t = Time.zone.now
      day = format_date_for_view(t, "%A")
      Timecop.freeze(t) do
        get "/calendar2"
        create_new_calendar_event
        select_frequency_option("Weekly on #{day}")
        expect(frequency_picker_value).to eq("Weekly on #{day}")

        select_frequency_option("Every weekday (Monday to Friday)")
        expect(frequency_picker_value).to eq("Every weekday (Monday to Friday)")
      end
    end

    it "selects monthly with specific day in frequency picker in dropdown" do
      get "/calendar2#view_name=month&view_start=2023-07-01"
      create_new_calendar_event
      newdate = "July 20, 2023"
      enter_new_event_date(newdate)

      select_frequency_option("Monthly on the third Thursday")
      expect(frequency_picker_value).to eq("Monthly on the third Thursday")
      click_submit_button
      get "/calendar2#view_name=month&view_start=2023-08-01"
      expect(all_events_in_month_view.length).to eq(1)
    end

    it "selects annually with specific day in frequency picker in dropdown" do
      get "/calendar2#view_name=month&view_start=2023-07-01"
      create_new_calendar_event
      newdate = "July 20, 2023"
      enter_new_event_date(newdate)

      select_frequency_option("Annually on July 20")
      expect(frequency_picker_value).to eq("Annually on July 20")
      click_submit_button

      get "/calendar2#view_name=month&view_start=2024-07-01"
      expect(all_events_in_month_view.length).to eq(1)
    end

    it "selects weekly with specific day in frequency picker in dropdown" do
      get "/calendar2#view_name=month&view_start=2023-07-01"
      create_new_calendar_event
      newdate = "July 20, 2023"
      enter_new_event_date(newdate)

      select_frequency_option("Weekly on Thursday")
      expect(frequency_picker_value).to eq("Weekly on Thursday")
      click_submit_button

      expect(all_events_in_month_view.length).to eq(3)
    end

    it "creates daily recurring event and verifies on month view calendar" do
      get "/calendar2#view_name=month&view_start=2023-07-01"
      create_new_calendar_event
      newdate = "July 20, 2023"
      enter_new_event_date(newdate)

      select_frequency_option("Daily")
      click_submit_button
      # show the events are in july calendar (includes both July and first week of August events on this view)
      get "/calendar2#view_name=month&view_start=2023-07-01"

      expect(all_events_in_month_view.length).to eq(17)
    end
  end

  context "calendar event modal interactions with custom recurring modal" do
    before :once do
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
    end

    it "goes to custom modal when custom is selected" do
      get "/calendar2"
      create_new_calendar_event

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed
    end

    it "makes custom change and returns to modal and new value in frequency field" do
      get "/calendar2"
      create_new_calendar_event

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      click_done_button
      expect(recurrence_modal_exists?).to be_falsey
      expect(frequency_picker_value).to eq("Daily, 5 times")
    end

    it "cancels custom change and returns to modal and original value in frequency field" do
      get "/calendar2"
      create_new_calendar_event

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      click_cancel_button
      expect(recurrence_modal_exists?).to be_falsey
      expect(frequency_picker_value).to eq("Does not repeat")
    end

    it "selects canned frequency and sees it in custom recurring modal" do
      get "/calendar2#view_name=month&view_start=2023-07-01"
      create_new_calendar_event
      newdate = "July 20, 2023"
      enter_new_event_date(newdate)

      select_frequency_option("Weekly on Thursday")
      select_frequency_option("Custom")

      expect(repeat_frequency_picker_value).to eq("Week")
    end
  end

  context "calendar event edit page" do
    before :once do
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
    end

    it "displays the frequency picker on calendar event edit page" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      expect(frequency_picker).to be_displayed
      expect(frequency_picker_value).to eq("Does not repeat")
    end

    it "selects the daily frequency in the calendar event modal" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      expect(frequency_picker).to be_displayed
      select_frequency_option("Daily")
      expect(frequency_picker_value).to eq("Daily")
    end

    it "creates recurring event and verifies monthly calendar" do
      skip("LF-578: Skipping due to performance issues")
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)
      select_frequency_option("Daily")
      click_create_event_button
      wait_for_ajaximations
      get "/calendar2#view_name=month&view_start=2023-07-01"
      wait_for_ajaximations
      expect(all_events_in_month_view.length).to eq(17)
    end

    it "selects the weekly, then weekdays frequency in the calendar event modal" do
      t = Time.zone.now
      day = format_date_for_view(t, "%A")

      Timecop.freeze(t) do
        get "/courses/#{@course.id}/calendar_events/new"
        wait_for_ajaximations
        wait_for_calendar_rce
        enter_calendar_start_date(format_date_for_view(t, "%b %e, %Y"))
        select_frequency_option("Weekly on #{day}")
        expect(frequency_picker_value).to eq("Weekly on #{day}")

        select_frequency_option("Every weekday (Monday to Friday)")
        expect(frequency_picker_value).to eq("Every weekday (Monday to Friday)")
      end
    end

    it "selects monthly with specific day in frequency picker in dropdown" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)

      select_frequency_option("Monthly on the third Thursday")
      expect(frequency_picker_value).to eq("Monthly on the third Thursday")
      click_create_event_button
      get "/calendar2#view_name=month&view_start=2023-08-01"
      expect(all_events_in_month_view.length).to eq(1)
    end

    it "selects annually with specific day in frequency picker in dropdown" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)

      select_frequency_option("Annually on July 20")
      expect(frequency_picker_value).to eq("Annually on July 20")
      click_create_event_button

      get "/calendar2#view_name=month&view_start=2024-07-01"
      expect(all_events_in_month_view.length).to eq(1)
    end

    it "shows the selected values from calendar modal on edit page" do
      get "/calendar2"
      wait_for_ajaximations
      create_new_calendar_event
      select_frequency_option("Daily")
      expect(frequency_picker_value).to eq("Daily")

      click_more_options_button
      expect(frequency_picker_value).to eq("Daily")
    end
  end

  context "calendar event edit page interactions with recurring modal" do
    before :once do
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
    end

    it "goes to custom modal when custom is selected" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)
      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed
    end

    it "makes custom change and returns to modal and new value in frequency field" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      click_done_button
      expect(recurrence_modal_exists?).to be_falsey
      expect(frequency_picker_value).to eq("Daily, 5 times")
    end

    it "cancels custom change and returns to modal and original value in frequency field" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      click_cancel_button
      expect(recurrence_modal_exists?).to be_falsey
      expect(frequency_picker_value).to eq("Does not repeat")
    end

    it "selects canned frequency and sees it in custom recurring modal" do
      get "/courses/#{@course.id}/calendar_events/new"
      wait_for_ajaximations
      wait_for_calendar_rce
      newdate = "July 20, 2023"
      enter_calendar_start_date(newdate)

      select_frequency_option("Weekly on Thursday")
      select_frequency_option("Custom")

      expect(repeat_frequency_picker_value).to eq("Week")
    end
  end

  context "delete recurring events" do
    before :once do
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
      today = Date.today
      start_at = Date.new(today.year, today.month, 15)
      create_calendar_event_series(@course, "event in a series", start_at)
    end

    it "deletes 'this event' from a series" do
      get "/calendar"

      events = events_in_a_series
      expect(events.length).to eq 3

      events[1].click
      hover_and_click delete_event_link_selector
      event_series_this_event.click
      event_series_delete_button.click
      wait_for_ajax_requests
      expect(events_in_a_series.length).to eq 2

      # make sure it was actually deleted and not just removed from the interface
      get("/calendar")
      expect(events_in_a_series.length).to eq 2
    end

    it "deletes 'this event and all following' from a series" do
      get "/calendar"

      events = events_in_a_series
      expect(events.length).to eq 3

      events[1].click
      hover_and_click delete_event_link_selector
      event_series_following_events.click
      event_series_delete_button.click
      wait_for_ajax_requests
      expect(events_in_a_series.length).to eq 1

      # make sure it was actually deleted and not just removed from the interface
      get("/calendar")
      expect(events_in_a_series.length).to eq 1
    end

    it "deletes 'all events' from a series" do
      get "/calendar"

      events = events_in_a_series
      expect(events.length).to eq 3

      events[1].click
      hover_and_click delete_event_link_selector
      event_series_all_events.click
      event_series_delete_button.click
      wait_for_ajax_requests
      expect(calendar_content).not_to contain_jqcss(events_in_a_series_selector)

      # make sure it was actually deleted and not just removed from the interface
      get("/calendar")
      expect(calendar_content).not_to contain_jqcss(events_in_a_series_selector)
    end
  end

  context "calendar event recurrence modal interactions" do
    before :once do
      course_with_teacher(active_all: true, new_user: true)
    end

    before do
      user_session(@teacher)
    end

    it "allows for selection of days with day view" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      enter_repeat_interval(5)
      expect(repeat_interval_value).to eq("5")

      click_done_button
      expect(frequency_picker_value).to eq("Every 5 days, 5 times")
    end

    it "shows an error with too many occurrences in AFTER mode" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      enter_repeat_interval(5)
      expect(repeat_interval_value).to eq("5")

      enter_recurrence_end_count(401)
      expect(recurrence_end_count_value).to eq("401")

      expect(custom_recurrence_modal.text).to include("Exceeds 400 occurrences limit")

      enter_recurrence_end_count(400)
      expect(recurrence_end_count_value).to eq("400")
      expect(custom_recurrence_modal.text).not_to include("Exceeds 400 occurrences limit")
    end

    it "shows an error with too many occurrences in ON mode" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      click_on_radio_button
      enter_recurrence_end_date("August 30, 2027")

      expect(custom_recurrence_modal.text).to include("Exceeds 400 events.")
      expect(custom_recurrence_modal.text).to include("Please pick an earlier date")

      enter_recurrence_end_date("August 30, 2023")

      expect(custom_recurrence_modal.text).not_to include("Exceeds 400 events.")
      expect(custom_recurrence_modal.text).not_to include("Please pick an earlier date")
    end

    it "allows for selection of number of months with 'On day' month type" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      enter_new_event_date("July 20, 2023")

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      enter_repeat_interval(5)
      expect(repeat_interval_value).to eq("5")

      select_repeat_frequency("Month")
      select_repeat_month_mode("on day 20")

      click_done_button
      expect(frequency_picker_value).to eq("Every 5 months on day 20, 5 times")
    end

    it "allows for selection of number of months with 'On the' month type" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      enter_new_event_date("July 20, 2023")

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      enter_repeat_interval(5)
      expect(repeat_interval_value).to eq("5")

      select_repeat_frequency("Month")
      select_repeat_month_mode("on the third Thursday")

      click_done_button
      expect(frequency_picker_value).to eq("Every 5 months on the third Thu, 5 times")
    end

    it "allows for selection of days for week type" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      enter_new_event_date("July 20, 2023")

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      enter_repeat_interval(5)
      expect(repeat_interval_value).to eq("5")

      select_repeat_frequency("Week")
      click_day_selection_checkbox("Mo")
      click_day_selection_checkbox("We")
      click_day_selection_checkbox("Th")

      expect(element_value_for_attr(day_of_week_input("Mo"), "aria-checked")).to eq("true")
      expect(element_value_for_attr(day_of_week_input("We"), "aria-checked")).to eq("true")
      expect(element_value_for_attr(day_of_week_input("Th"), "aria-checked")).to eq("false")

      click_done_button
      expect(frequency_picker_value).to eq("Every 5 weeks on Mon, Wed, 5 times")
    end

    it "allows for selection of days for week type with specific end date" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      enter_new_event_date("July 20, 2023")

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      select_repeat_frequency("Week")
      click_day_selection_checkbox("Tu")
      click_day_selection_checkbox("Th")

      click_on_radio_button
      enter_recurrence_end_date("August 30, 2023")

      click_done_button

      expect(frequency_picker_value).to eq("Weekly on Tue until Aug 30, 2023")
    end

    it "allows for selection of years with specific end date" do
      get "/calendar2#view_name=month&view_start=2023-07-01"

      wait_for_ajaximations
      create_new_calendar_event
      enter_new_event_date("July 20, 2023")

      select_frequency_option("Custom")
      expect(custom_recurrence_modal).to be_displayed

      select_repeat_frequency("Year")

      enter_repeat_interval(2)
      expect(repeat_interval_value).to eq("2")

      click_on_radio_button
      enter_recurrence_end_date("August 30, 2027")

      click_done_button

      expect(frequency_picker_value).to eq("Every 2 years on Jul 20 until Aug 30, 2027")
    end
  end
end
