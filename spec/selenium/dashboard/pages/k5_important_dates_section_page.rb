# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../../helpers/color_common"

module K5ImportantDatesSectionPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------

  def add_override_selector
    "#add_due_date"
  end

  def assignment_icon_selector
    "[data-testid='date-icon-wrapper']"
  end

  def assignment_important_dates_block_selector
    "#edit_assignment_form #important_dates"
  end

  def calendar_add_selector
    "#create_new_event_link"
  end

  def calendar_assignment_mark_dates_selector
    "#edit_assignment_form #calendar_event_important_dates"
  end

  def calendar_assignment_modal_submit_selector
    "#edit_assignment_form .event-details-footer button[type='submit']"
  end

  def calendar_assignment_subject_selector
    "#assignment_context"
  end

  def calendar_assignment_title_selector
    "#edit_assignment_form #assignment_title"
  end

  def calendar_choose_text_selector
    "[data-testid='calendar-selection-text']"
  end

  def calendar_edit_dialog_selector
    "#edit-event"
  end

  def calendar_event_more_options_selector
    "button[data-testid='edit-calendar-event-more-options-button']"
  end

  def calendar_event_submit_button_selector
    "button[type='submit']"
  end

  def calendar_for_subject_selector
    "[data-testid='edit-calendar-event-form-context']"
  end

  def calendars_left_text_selector
    "[data-testid='calendars-left-text']"
  end

  def calendar_mark_important_dates_selector
    "label[for='k5-field'] div"
  end

  def more_options_mark_important_dates_selector
    "#calendar_event_important_dates"
  end

  def calendar_modal_selector
    "[aria-label='Calendars']"
  end

  def calendar_modal_cancel_selector
    "//button[.//*[. = 'Cancel']]"
  end

  def calendar_modal_close_button_selector
    "[data-testid='instui-modal-close']"
  end

  def calendar_modal_submit_selector
    "//button[.//*[. = 'Submit']]"
  end

  def calendar_picker_gear_selector
    "[data-testid='filter-important-dates-button']"
  end

  def date_field_selector
    ".date_field[data-date-type='due_at']"
  end

  def edit_assignment_selector
    ".edit_assignment_option"
  end

  def edit_assignment_submit_selector
    "#edit_assignment_form"
  end

  def edit_discussion_submit_selector
    "#edit_discussion_form_buttons"
  end

  def edit_quiz_submit_selector
    "#quiz_edit_actions"
  end

  def important_date_icon_selector(icon_type)
    "svg[name='#{icon_type}']"
  end

  def important_date_link_selector
    "[data-testid='important-date-link']"
  end

  def important_date_subject_selector
    "[data-testid='important-date-subject']"
  end

  def important_dates_block_selector
    "#important_dates"
  end

  def important_dates_title_selector
    "h2:contains('Important Dates')"
  end

  def mark_important_dates_selector
    "input + label:contains('Mark as important date and show on homeroom sidebar')"
  end

  def mark_important_dates_input_selector
    "[name='important_dates']"
  end

  def no_important_dates_image_selector
    "[data-testid='important-dates-panda']"
  end

  def subject_list_input_selector
    "[data-testid='subject-calendars']"
  end

  def subject_list_xpath_selector
    "//label[..//input[@data-testid = 'subject-calendars']]"
  end

  #------------------------- Elements --------------------------

  def add_override
    f(add_override_selector)
  end

  def assignment_icon
    f(assignment_icon_selector)
  end

  def assignment_important_dates_block
    f(assignment_important_dates_block_selector)
  end

  def assignment_link(link_text)
    fln(link_text)
  end

  def calendar_add
    f(calendar_add_selector)
  end

  def calendar_assignment_mark_dates
    f(calendar_assignment_mark_dates_selector)
  end

  def calendar_assignment_title
    f(calendar_assignment_title_selector)
  end

  def calendar_choose_text
    f(calendar_choose_text_selector)
  end

  def calendar_edit_dialog
    f(calendar_edit_dialog_selector)
  end

  def calendar_event_submit_button
    f(calendar_event_submit_button_selector)
  end

  def calendar_event_more_options_button
    fj(calendar_event_more_options_selector)
  end

  def calendar_for_subject
    f(calendar_for_subject_selector)
  end

  def calendars_left_text
    f(calendars_left_text_selector)
  end

  def calendar_mark_important_dates
    f(calendar_mark_important_dates_selector)
  end

  def calendar_modal
    f(calendar_modal_selector)
  end

  def calendar_modal_cancel
    fxpath(calendar_modal_cancel_selector)
  end

  def calendar_modal_close_button
    f(calendar_modal_close_button_selector)
  end

  def calendar_modal_submit
    fxpath(calendar_modal_submit_selector)
  end

  def calendar_assignment_modal_submit
    f(calendar_assignment_modal_submit_selector)
  end

  def calendar_picker_gear
    f(calendar_picker_gear_selector)
  end

  def date_field
    ff(date_field_selector)
  end

  def edit_assignment
    f(edit_assignment_selector)
  end

  def important_date_icon(icon_type)
    f(important_date_icon_selector(icon_type))
  end

  def important_date_link
    f(important_date_link_selector)
  end

  def important_date_subject
    f(important_date_subject_selector)
  end

  def important_date_subject_list
    ff(important_date_subject_selector)
  end

  def important_dates_block
    f(important_dates_block_selector)
  end

  def important_dates_title
    fj(important_dates_title_selector)
  end

  def mark_important_dates
    fj(mark_important_dates_selector)
  end

  def mark_important_dates_input
    f(mark_important_dates_input_selector)
  end

  def no_important_dates_image
    f(no_important_dates_image_selector)
  end

  def subject_list_input
    ff(subject_list_input_selector)
  end

  def subject_list_xpath
    ffxpath(subject_list_xpath_selector)
  end

  #----------------------- Actions & Methods -------------------------

  def calendar_dialog_exists?
    element_exists?(calendar_edit_dialog_selector)
  end

  def calendar_mark_important_dates_exists?
    element_exists?(calendar_mark_important_dates_selector)
  end

  def important_date_icon_exists?(icon_name)
    element_exists?(important_date_icon_selector(icon_name))
  end

  def set_and_tab_out_of_date_field(date_field_index, due_at)
    date_field[date_field_index].send_keys(format_date_for_view(due_at), :tab)
  end

  def clear_date_field(date_field_index)
    date_field[date_field_index].clear
  end

  def create_important_date_assignment(course, title, due_at)
    assignment = create_dated_assignment(course, title, due_at)
    assignment.update!(important_dates: true)
    assignment
  end

  #----------------------- Click Items -------------------------------

  def click_calendar_add
    calendar_add.click
  end

  def click_calendar_assignment_mark_dates
    calendar_assignment_mark_dates.click
  end

  def click_calendar_event_more_options_button
    calendar_event_more_options_button.click
  end

  def click_calendar_event_submit_button
    calendar_event_submit_button.click
  end

  def click_calendar_gear
    calendar_picker_gear.click
  end

  def click_calendar_mark_important_dates
    calendar_mark_important_dates.click
  end

  def click_calendar_modal_cancel
    calendar_modal_cancel.click
    wait_for_ajaximations
  end

  def click_calendar_modal_close
    calendar_modal_close_button.click
    wait_for_ajaximations
  end

  def click_calendar_modal_submit
    calendar_modal_submit.click
    wait_for_ajaximations
  end

  def click_calendar_assignment_modal_submit
    calendar_assignment_modal_submit.click
    wait_for_ajaximations
  end

  def click_calendar_picker_gear
    calendar_picker_gear.click
  end

  def click_calendar_subject(subject_name)
    click_option(calendar_for_subject, subject_name)
  end

  def click_assignment_calendar_subject(subject_name)
    click_option(calendar_assignment_subject_selector, subject_name)
  end

  def click_add_override
    add_override.click
  end

  def click_edit_assignment
    edit_assignment.click
  end

  def click_important_date_link
    important_date_link.click
  end

  def click_mark_important_dates
    mark_important_dates.click
  end

  def click_subject_calendar_checkbox(checkbox_item)
    subject_list_xpath[checkbox_item].click
  end

  #------------------------------Retrieve Text----------------------#

  def subject_list_text
    subject_list_xpath.map(&:text)
  end

  #----------------------------Element Management---------------------#

  def calendar_modal_exists?
    element_exists?(calendar_modal_selector)
  end

  def is_calendar_modal_gone?
    wait_for_no_such_element { calendar_modal }
  end
end
