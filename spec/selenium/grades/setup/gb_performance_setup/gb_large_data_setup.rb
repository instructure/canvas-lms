#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../../../helpers/gradebook_common'

module GradebookLargeDataSetup
  def init_course_with_students(num = 1)
    course_with_teacher(active_all: true)

    @students = []
    (1..num).each do |i|
      student = User.create!(name: "Student_#{i}")
      student.register!

      e1 = @course.enroll_student(student)
      e1.update!(workflow_state: 'active')

      @students.push student
    end
  end

  def gradebook_data_setup(opts={})
    assignment_setup_defaults
    assignment_setup(opts)
  end

  def assignment_setup_defaults
    @assignment_1_points = "10"
    @assignment_2_points = "5"
    @assignment_3_points = "50"


    @student_name_1 = "student 1"
    @student_name_2 = "student 2"
    @student_name_3 = "student 3"

    @student_1_total_ignoring_ungraded = "100%"
    @student_2_total_ignoring_ungraded = "66.67%"
    @student_3_total_ignoring_ungraded = "66.67%"
    @student_1_total_treating_ungraded_as_zeros = "18.75%"
    @student_2_total_treating_ungraded_as_zeros = "12.5%"
    @student_3_total_treating_ungraded_as_zeros = "12.5%"
    @default_password = "qwertyuiop"
  end

  def assignment_setup(opts={})
    course_with_teacher({ active_all: true }.merge(opts))
    @course.grading_standard_enabled = true
    @course.save!

    init_course_with_students(100)

    # first assignment data
    @group = @course.assignment_groups.create!(name: 'first assignment group', group_weight: 100)
    @first_assignment = assignment_model({
                                           course: @course,
                                           name: 'A name that would not reasonably fit in the header cell which should have some limit set',
                                           due_at: nil,
                                           points_possible: 10,
                                           submission_types: 'online_text_entry,online_upload',
                                           assignment_group: @group
                                         })
    rubric_model
    @association = @rubric.associate_with(@assignment, @course, purpose: 'grading')
    @assignment.submit_homework(@student_1, body: 'student 1 submission assignment 1')
    @assignment.grade_student(@student_1, grade: 10, grader: @teacher)
  end
end
