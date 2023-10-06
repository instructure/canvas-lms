# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class SRGB
  class << self
    include SeleniumDependencies

    ASSIGNMENT_SORT_ORDER_OPTIONS = {
      assignment_group: "By Assignment Group and Position",
      alpha: "Alphabetically",
      due_date: "By Due Date"
    }.freeze

    def switch_to_default_gradebook_link
      f("#switch_to_default_gradebook")
    end

    def switch_to_default_gradebook
      f('[data-testid="gradebook-select-dropdown"]').click
      wait_for_animations
      fj("[role=\"menuitemradio\"]:contains(\"Gradebook\")").click
    end

    def assignment_sorting_dropdown
      f(assignment_sort_order_selector)
    end

    def main_grade_input
      f("#student_and_assignment_grade")
    end

    def excuse_checkbox
      f("#submission-excused")
    end

    def grade_for_label
      f("label[for='student_and_assignment_grade']")
    end

    def proxy_submitter_label
      f("label[for='proxy_submitter']")
    end

    def next_assignment_button
      fj("button:contains('Next Assignment')")
    end

    def submission_details_button
      f("#submission_details")
    end

    def submit_for_student_button
      f("#proxy_upload_trigger")
    end

    def notes_field
      fj("#student_information textarea:visible:not([disabled])")
    end

    def final_grade
      f("#student_information .total-grade")
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
      f(".assignment-subtotal-grade .grade")
    end

    def secondary_id_label
      f("#student_information .secondary_id")
    end

    def grading_period_dropdown
      f("#grading_period_select")
    end

    def student_dropdown
      f("#student_select")
    end

    def assignment_dropdown
      f("#assignment_select")
    end

    def default_grade
      f("#set_default_grade")
    end

    def curve_grade_button
      f("#curve_grades")
    end

    # global checkboxes
    def ungraded_as_zero
      f("#ungraded")
    end

    def hide_student_names
      f("#hide_names_checkbox")
    end

    def concluded_enrollments
      f("#concluded_enrollments")
    end

    def show_notes_option
      f("#show_notes")
    end

    def allow_final_grade_override_option
      f("#allow_final_grade_override")
    end

    def all_content
      f("#content")
    end

    # content selection buttons
    def previous_student
      f(".student_navigation button.previous_object")
    end

    def next_student
      f(".student_navigation button.next_object")
    end

    def previous_assignment
      f(".assignment_navigation button.previous_object")
    end

    def next_assignment
      f(".assignment_navigation button.next_object")
    end

    # assignment information
    def assignment_link
      f(".assignment_selection a")
    end

    def speedgrader_link
      f("#assignment-speedgrader-link")
    end

    def assignment_scores
      f("#assignment_information .ic-Table tbody tr")
    end

    def visit(course_id)
      get "/courses/#{course_id}/gradebook/change_gradebook_version?version=srgb"
    end

    def sort_assignments_by(sort_order)
      opt_name = ASSIGNMENT_SORT_ORDER_OPTIONS[sort_order.to_sym]
      opt_name ||= ASSIGNMENT_SORT_ORDER_OPTIONS[ASSIGNMENT_SORT_ORDER_OPTIONS.invert[sort_order]]
      return unless opt_name

      click_option(assignment_sorting_dropdown, opt_name.to_s)
    end

    def assignment_sort_order
      get_value(assignment_sort_order_selector)
    end

    def select_assignment(assignment)
      click_option(assignment_dropdown, assignment.name)
    end

    def select_student(student)
      click_option(student_dropdown, student.sortable_name)
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

    private

    def assignment_sort_order_selector
      "select#arrange_assignments"
    end
  end
end
