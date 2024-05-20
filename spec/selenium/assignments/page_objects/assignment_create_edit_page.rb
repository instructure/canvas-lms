# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AssignmentCreateEditPage
  class << self
    include SeleniumDependencies

    # CSS Selectors

    def manage_assign_to_button_selector
      "[data-testid='manage-assign-to']"
    end

    def pending_changes_pill_selector
      "[data-testid='pending_changes_pill']"
    end

    def submission_type_selector
      "#assignment_submission_type"
    end

    def text_entry_submission_type_toggle_selector
      "#assignment_text_entry"
    end

    # Selectors
    def assignment_form
      f("#edit_assignment_form")
    end

    def assignment_name_textfield
      f("#assignment_name")
    end

    def assignment_save_button
      find_button("Save")
    end

    def assignment_cancel_button
      find_button("Cancel")
    end

    def save_publish_button
      find_button("Save & Publish")
    end

    def points_possible
      f("#assignment_points_possible")
    end

    def display_grade_as
      f("#assignment_grading_type")
    end

    def submission_type
      f("#assignment_submission_type")
    end

    def limited_attempts_fieldset
      f("#allowed_attempts_fields")
    end

    def limited_attempts_dropdown
      f("#allowed-attempts-target select")
    end

    def limited_attempts_input
      f("input[name='allowed_attempts']")
    end

    def increase_attempts_btn
      f("button svg[name='IconArrowOpenUp']")
    end

    def decrease_attempts_btn
      f("button svg[name='IconArrowOpenDown']")
    end

    def due_date_picker_btn
      f("#overrides-wrapper button.ui-datepicker-trigger.btn")
    end

    def due_date_picker_popup
      f("#ui-datepicker-div")
    end

    def due_date_picker_done_btn
      f("button.ui-datepicker-ok")
    end

    def due_date_input
      f("input.datePickerDateField.DueDateInput")
    end

    # Moderated Grading Options
    def select_grader_dropdown
      f("select[name='final_grader_id']")
    end

    def grader_count_input
      f(".ModeratedGrading__GraderCountInputContainer input")
    end

    def moderate_checkbox
      f("input[type=checkbox][name='moderated_grading']")
    end

    def filter_grader(grader_name)
      fj("option:contains(\"#{grader_name}\")")
    end

    def assignment_edit_permission_error_text
      f("#unauthorized_message")
    end

    def hide_from_gradebooks_checkbox
      f("#assignment_hide_in_gradebook")
    end

    def manage_assign_to_button
      f(manage_assign_to_button_selector)
    end

    def omit_from_final_grade_checkbox
      f("#assignment_omit_from_final_grade")
    end

    def text_entry_submission_type_toggle
      f(text_entry_submission_type_toggle_selector)
    end

    def pending_changes_pill
      f(pending_changes_pill_selector)
    end

    # Methods & Actions
    def visit_assignment_edit_page(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}/edit"
    end

    def visit_new_assignment_create_page(course)
      get "/courses/#{course}/assignments/new"
    end

    def edit_assignment_name(text)
      assignment_name_textfield.send_keys(text)
    end

    def replace_assignment_name(text)
      assignment_name_textfield.send_keys([:control, "a"], :backspace, text)
    end

    def add_number_of_graders(number)
      replace_content(grader_count_input, number, tab_out: true)
    end

    def click_manage_assign_to_button
      manage_assign_to_button.click
    end

    def select_moderate_checkbox
      moderate_checkbox.click
    end

    def select_grader_from_dropdown(grader_name)
      filter_grader(grader_name).click
    end

    def save_assignment
      wait_for_new_page_load { assignment_save_button.click }
    end

    def save_and_publish
      wait_for_new_page_load { save_publish_button.click }
    end

    def cancel_assignment
      wait_for_new_page_load { assignment_cancel_button.click }
    end

    def select_grading_type(type, select_by = :text)
      click_option(display_grade_as, type, select_by)
    end

    def select_text_entry_submission_type
      text_entry_submission_type_toggle.click
    end

    def enter_points_possible(points)
      replace_content points_possible, points
    end

    def select_submission_type(type, select_by = :text)
      click_option(submission_type, type, select_by)
    end

    def pending_changes_pill_exists?
      element_exists?(pending_changes_pill_selector)
    end
  end
end
