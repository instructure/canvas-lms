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
require_relative "gradebook_grade_detail_tray_page"

module Gradebook
  class Cells
    class << self
      include SeleniumDependencies

      # ---------- Student Cells ---------------
      def student_cell_selector(student)
        ".slick-row.student_#{student.id} .student-name"
      end

      def student_cell(student)
        f(student_cell_selector(student))
      end

      def student_cell_name_link(student)
        f("#{student_cell_selector(student)} .student-grades-link")
      end

      # ---------- Grading Cells ---------------
      def grading_cell_selector(student, assignment)
        ".slick-row.student_#{student.id} .slick-cell.assignment_#{assignment.id}"
      end

      def ungradable_selector
        ".cannot_edit"
      end

      def grading_cell(student, assignment)
        f(grading_cell_selector(student, assignment))
      end

      def grading_cell_input(student, assignment)
        f("#{grading_cell_selector(student, assignment)} input[type='text']")
      end

      def grid_assignment_row_cell(student, assignment)
        grading_cell(student, assignment).find(".Grid__GradeCell")
      end

      def grading_cell_menu_button(student, assignment, menu_selector:)
        f("#{grading_cell_selector(student, assignment)} .Grid__GradeCell__#{menu_selector}Menu button")
      end

      def grade_tray_button_selector
        ".Grid__GradeCell__Options button"
      end

      def grade_tray_button
        f(grade_tray_button_selector)
      end

      def get_grade(student, assignment)
        grading_cell(student, assignment).text.strip
      end

      def edit_grade(student, assignment, grade)
        cell_selector = grading_cell_selector(student, assignment)
        f(cell_selector).click

        grade_input = grading_cell_input(student, assignment)
        set_value(grade_input, grade)

        grade_input.send_keys(:return)
      end

      def select_scheme_grade(student, assignment, grade)
        select_grade_from_menu(student, assignment, grade, "GradingScheme")
      end

      def select_complete_incomplete_grade(student, assignment, grade)
        select_grade_from_menu(student, assignment, grade, "CompleteIncomplete")
      end

      def select_grade_from_menu(student, assignment, grade, menu_selector)
        grading_cell(student, assignment).click

        button = grading_cell_menu_button(student, assignment, menu_selector:)
        button.click

        grade_item = ff("ul[aria-labelledby='#{button.attribute("id")}'] li").detect do |element|
          element.text.chomp == grade # find exact grade match "B+" != "B"
        end
        grade_item.click

        button.send_keys(:down) # commit the grade change
      end

      def send_keyboard_shortcut(student, assignment, key)
        grading_cell(student, assignment).click
        driver.action.send_keys(:escape).perform
        driver.action.send_keys(key).perform
        wait_for_animations
      end

      def open_tray(student, assignment)
        grading_cell(student, assignment).click
        grade_tray_button.click
        Gradebook::GradeDetailTray.submission_tray_full_content
        wait_for_ajaximations
      end

      # ---------- Assignment Cells ---------------
      def assignment_group_selector(student, assignment_group)
        ".slick-row.student_#{student.id} .slick-cell.assignment_group_#{assignment_group.id}"
      end

      def get_assignment_group_grade(student, assignment_group)
        f(assignment_group_selector(student, assignment_group)).text
      end

      def send_keyboard_shortcut_to_assignment_group(student, assignment_group, key)
        f(assignment_group_selector(student, assignment_group)).click
        driver.action.send_keys(:escape).perform
        driver.action.send_keys(key).perform
        wait_for_animations
      end

      def assignments_header(index)
        f("#gradebook_grid .container_1 .slick-header-column:nth-child(#{index})")
      end

      # ---------- Total Grade Cells ---------------
      def total_grade_selector(student)
        ".slick-row.student_#{student.id} .slick-cell.total_grade"
      end

      def get_total_grade(student)
        f(total_grade_selector(student)).text
      end

      def send_keyboard_shortcut_to_total(student, key)
        f(total_grade_selector(student)).click
        driver.action.send_keys(:escape).perform
        driver.action.send_keys(key).perform
        wait_for_animations
      end

      # ---------- Grade Override Cells ---------------
      def grade_override_selector(student)
        ".slick-row.student_#{student.id} .slick-cell.total-grade-override"
      end

      def grade_override_input(student)
        f("#{grade_override_selector(student)} input[type='text']")
      end

      def get_override_grade(student)
        f(grade_override_selector(student)).text
      end

      def edit_override(student, grade)
        f(grade_override_selector(student)).click

        override_input = grade_override_input(student)
        set_value(override_input, grade)

        override_input.send_keys(:return)
      end
    end
  end
end
