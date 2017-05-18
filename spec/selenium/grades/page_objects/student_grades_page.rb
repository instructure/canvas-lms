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

class StudentGradesPage
  include SeleniumDependencies

  # Period components
  def period_options_css
    '.grading_periods_selector > option'
  end

  # Assignment components
  def assignment_titles_css
    '.student_assignment > th > a'
  end

  def visit_as_teacher(course, student)
    get "/courses/#{course.id}/grades/#{student.id}"
  end

  def visit_as_student(course)
    get "/courses/#{course.id}/grades"
  end

  def final_grade
    f('#submission_final-grade .grade')
  end

  def final_points_possible
    f('#submission_final-grade .points_possible')
  end

  def grading_period_dropdown
    f('.grading_periods_selector')
  end

  def select_period_by_name(name)
    click_option(grading_period_dropdown, name)
  end

  def assignment_titles
    ff(assignment_titles_css).map(&:text)
  end

  def assignment_row(assignment)
    f("#submission_#{assignment.id}")
  end

  def toggle_comment_module
    fj('.toggle_comments_link .icon-discussion:first').click
  end
end
