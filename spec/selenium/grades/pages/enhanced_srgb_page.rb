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

require_relative "../../common"

class EnhancedSRGB
  class << self
    include SeleniumDependencies

    def switch_to_default_gradebook
      f('[data-testid="gradebook-select-dropdown"]').click
      f('[data-testid="default-gradebook-menu-option"]').click
    end

    def main_grade_input
      f('[data-testid="student_and_assignment_grade_input"]')
    end

    def submission_late_penalty_label
      f('[data-testid="submission_late_penalty_label"]')
    end

    def late_penalty_final_grade_label
      f('[data-testid="late_penalty_final_grade_label"]')
    end

    def pass_fail_grade_select
      f('[data-testid="student_and_assignment_grade_select"]')
    end

    def out_of_text
      f('[data-testid="student_and_assignment_grade_out_of_text"]')
    end

    def excuse_checkbox
      f("#excuse_assignment")
    end

    def grade_for_label
      f('[data-testid="student_and_assignment_grade_label"]')
    end

    def proxy_submitter_label
      f('[data-testid="submitter-name"]')
    end

    def no_points_possible_warning
      f('[data-testid="no-points-possible-warning"]')
    end

    def assignment_group_no_points_warning
      f('[data-testid="assignment-group-no-points-warning"]')
    end

    def next_assignment_button
      fj("button:contains('Next Assignment')")
    end

    def submission_status_pill
      f('[data-testid="submission-status-pill"]')
    end

    def submission_details_button
      f('[data-testid="submission-details-button"]')
    end

    def submission_details_submit_button
      f('[data-testid="submission-details-submit-button"]')
    end

    def submission_details_grade_input
      f('[data-testid="submission_details_grade_input"]')
    end

    def submission_details_assignment_name
      f('[data-testid="submission-details-assignment-name"]')
    end

    def submit_for_student_button
      f('[data-testid="proxy-submission-button"]')
    end

    def notes_field
      f('[data-testid="notes-text-box"]')
    end

    def section_select
      f("#section_select")
    end

    def section_select_options
      Selenium::WebDriver::Support::Select.new(f("#section_select")).options.map(&:text)
    end

    def sort_assignments_select
      f('[data-testid="sort-select"]')
    end

    def sort_assignments_select_options
      Selenium::WebDriver::Support::Select.new(f('[data-testid="sort-select"]')).options.map(&:text)
    end

    def assignment_group_sort_string
      "By Assignment Group and Position"
    end

    def assignment_group_sort_value
      "assignmentGroup"
    end

    def assignment_alpha_sort_string
      "Alphabetically"
    end

    def assignment_alpha_sort_value
      "alphabetical"
    end

    def assignment_due_date_sort_string
      "By Due Date"
    end

    def assignment_due_date_sort_value
      "dueDate"
    end

    def final_grade
      f(".total-grade")
    end

    def final_grade_override
      f("#final-grade-override")
    end

    def final_grade_override_input
      f("#final-grade-override-input")
    end

    def assignment_muted_checkbox
      f("#assignment_muted_check")
    end

    def assignment_mute_dialog_button
      fj("button:contains('Unmute Assignment')")
    end

    def assign_subtotal_grade
      ff('td[data-testid="subtotal-grade"]')
    end

    def secondary_id_label
      f(".secondary_id")
    end

    def student_information_name
      f('[data-testid="student-information-name"]')
    end

    def grading_period_dropdown
      f("#grading_period_select")
    end

    def student_dropdown
      f('[data-testid="content-selection-student-select"]')
    end

    def assignment_dropdown
      f('[data-testid="content-selection-assignment-select"]')
    end

    def default_grade
      f('[data-testid="default-grade-button"]')
    end

    def default_grade_input
      f('[data-testid="default-grade-input"]')
    end

    def default_grade_submit_button
      f('[data-testid="default-grade-submit-button"]')
    end

    def default_grade_close_button
      f('[data-testid="default-grade-close-button"]')
    end

    def dropped_message
      f('[data-testid="dropped-assignment-message"]')
    end

    def curve_grade_button
      f('[data-testid="curve-grades-button"]')
    end

    # global checkboxes
    def ungraded_as_zero
      f('[data-testid="include-ungraded-assignments-checkbox"]')
    end

    def hide_student_names
      f('[data-testid="hide-student-names-checkbox"]')
    end

    def concluded_enrollments
      f('[data-testid="show-concluded-enrollments-checkbox"]')
    end

    def show_notes_option
      f('[data-testid="show-notes-column-checkbox"]')
    end

    def allow_final_grade_override_option
      f("#allow_final_grade_override")
    end

    def all_content
      f("#content")
    end

    # content selection buttons
    def previous_student
      f('[data-testid="previous-student-button"]')
    end

    def next_student
      f('[data-testid="next-student-button"]')
    end

    def previous_assignment
      f('[data-testid="previous-assignment-button"]')
    end

    def next_assignment
      f('[data-testid="next-assignment-button"]')
    end

    # assignment information

    def assignment_information
      f('[data-testid="assignment-information"]')
    end

    def assignment_link
      f('[data-testid="assignment-information-name"]')
    end

    def speedgrader_link
      f('[data-testid="assignment-speedgrader-link"]')
    end

    def assignment_submission_info
      f('[data-testid="assignment-submission-info"]')
    end

    def assignment_points_possible
      f('[data-testid="assignment-points-possible"]')
    end

    def assignment_average
      f('[data-testid="assignment-average"]')
    end

    def assignment_max
      f('[data-testid="assignment-max"]')
    end

    def assignment_min
      f('[data-testid="assignment-min"]')
    end

    def message_students_button
      f('[data-testid="message-students-who-button"]')
    end

    def message_students_input
      f('[data-testid="message-input"]')
    end

    def message_students_submit_button
      f('[data-testid="send-message-button"]')
    end

    def download_submissions_button
      f('[data-testid="download-all-submissions-button"]')
    end

    def visit(course_id)
      get "/courses/#{course_id}/gradebook/change_gradebook_version?version=individual_enhanced"
    end

    def sort_assignments_by(sort_order)
      click_option(sort_assignments_select, sort_order)
    end

    def assignment_sort_order
      sort_assignments_select.attribute("value")
    end

    def select_assignment(assignment)
      click_option(assignment_dropdown, assignment.name)
    end

    def assignment_dropdown_options
      get_options('[data-testid="content-selection-assignment-select"]').map(&:text)
    end

    def select_student(student)
      click_option(student_dropdown, student.sortable_name)
    end

    def student_dropdown_options
      get_options('[data-testid="content-selection-student-select"]').map(&:text)
    end

    def select_grading_period(grading_period)
      click_option(grading_period_dropdown, grading_period)
    end

    def enter_grade(grade)
      replace_content(main_grade_input, grade)
      tab_out_of_input(main_grade_input)
    end

    def enter_override_grade(grade)
      replace_content(final_grade_override_input, grade)
      tab_out_of_input(final_grade_override_input)
    end

    def current_grade
      main_grade_input["value"]
    end

    def grading_enabled?
      main_grade_input.enabled?
    end

    def grade_srgb_assignment(input, grade)
      replace_content(input, grade)
    end

    def tab_out_of_input(input_selector)
      # This is a hack for a timing issue with SRGB
      2.times { input_selector.send_keys(:tab) }
      wait_for_ajaximations
    end

    def drop_lowest(course, num_assignment)
      ag = course.assignment_groups.first
      ag.rules_hash = { "drop_lowest" => num_assignment }
      ag.save!
    end

    def total_score
      final_grade.text
    end
  end
end
