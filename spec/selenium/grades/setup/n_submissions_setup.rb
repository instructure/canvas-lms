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

module NSubmisssionsSetup

  # use this to create X students and Y assignments = XY Submissions
  # Note: This can be used for 200 submissions, beyond that might not be supported on current Jenkins

  def submissions_setup(number_of_students, number_of_assignments, opts={})
    course_with_teacher({ active_all: true }.merge(opts))
    @course.grading_standard_enabled = true
    @course.save!

    @students = create_users_in_course(@course,number_of_students)

    # assignment data
    @group = @course.assignment_groups.create!(name: 'first assignment group', group_weight: 100)
    @assignments = []
    (1..number_of_assignments).each do |assignment_number|
      assignment = assignment_model({
                                    course: @course,
                                    name: "Assignment_#{assignment_number}",
                                    due_at: nil,
                                    points_possible: 10,
                                    submission_types: 'online_text_entry,online_upload',
                                    assignment_group: @group
                                  })
      @students[0..number_of_students].map{ |student_id| assignment.grade_student(User.find(student_id), grade: 10, grader: @teacher) }
      @assignments.push assignment
    end
  end
end
