#
# Copyright (C) 2018 - present Instructure, Inc.
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

class ModeratePage
  class << self
    include SeleniumDependencies

    # Actions

    def visit(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}/moderate"
    end

    def select_provisional_grade_for_student_by_position(student, position)
      f('input', student_table_row_by_displayed_name(student.name)).click
      ff('li', student_table_row_by_displayed_name(student.name))[position].click
    end

    def click_post_grades_button
      post_grades_button.click
    end

    # Methods

    def fetch_student_count
      student_table_row_headers.size
    end

    def fetch_provisional_grade_count_for_student(student)
      ff('.GradesGrid__ProvisionalGradeCell', student_table_row_by_displayed_name(student.name)).size
    end

    # Components

    def main_content_area
      f("#main")
    end

    def student_table_headers
      ff('.GradesGrid__GraderHeader')
    end

    def student_table_row_headers
      ff('.GradesGrid__BodyRowHeader')
    end

    def student_table_row_by_displayed_name(name)
      fj(".GradesGrid__BodyRow:contains('#{name}')")
    end

    def post_grades_button
      fj("button:contains('Post')")
    end

    def grades_posted_button
      fj("button:contains('Grades Posted')")
    end
  end
end
