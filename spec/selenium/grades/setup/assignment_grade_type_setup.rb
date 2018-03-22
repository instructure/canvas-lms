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

require_relative '../../helpers/gradezilla_common'

module AssignmentGradeTypeSetup
  include GradezillaCommon

  def entering_grades_setup(grading_type, grade)
    init_course_with_students 1
    @assignment = @course.assignments.create!(grading_type: grading_type, points_possible: 10)
    @assignment.grade_student(@students[0], grade: grade, grader: @teacher)
  end
end

