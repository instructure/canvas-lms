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

require_relative '../../common'

class Gradezilla
  class Cells
    class << self
      include SeleniumDependencies

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

      def get_grade(student, assignment)
        grading_cell(student, assignment).text
      end

      def edit_grade(student, assignment, grade)
        cell_selector = grading_cell_selector(student, assignment)
        f(cell_selector).click

        grade_input = f("#{cell_selector} .grade")
        set_value(grade_input, grade)

        grade_input.send_keys(:return)
        wait_for_ajax_requests
      end

      def open_tray(student, assignment)
        cell = grading_cell(student, assignment)
        cell.click
        fj('button:contains("Open submission tray")', cell).click
        wait_for_ajaximations
      end

      # ---------- Assignment Group Cells ---------------
      def assignment_group_selector(student, assignment_group)
        ".slick-row.student_#{student.id} .slick-cell.assignment_group_#{assignment_group.id}"
      end

      def get_assignment_group_grade(student, assignment)
        f(assignment_group_selector(student, assignment)).text
      end

      # ---------- Total Grade Cells ---------------
      def total_grade_selector(student)
        ".slick-row.student_#{student.id} .slick-cell.total_grade"
      end

      def get_total_grade(student)
        f(total_grade_selector(student)).text
      end
    end
  end
end
