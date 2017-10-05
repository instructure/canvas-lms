#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../setup/gradebook_setup'
require_relative '../../helpers/gradezilla_common'

module GradebookHistorySetup
  include GradezillaCommon
  include GradebookSetup

  def gb_history_setup(number_of_history_records)
    init_course_with_students(1)
    now = Time.zone.now

    # create 1 assignments due in the past,
    # and 2 in future
    create_assignment_past_due_day(now)
    create_assignment_due_one_day(now)
    create_assignment_due_one_week(now)

    Timecop.freeze(now) do
      student_submits_assignments
    end

    number_of_history_records.times do
      teacher_grades_assignments
    end
  end

  def create_assignment_past_due_day(now)
    @assignment_past_due_day = @course.assignments.create!(
      title: 'assignment one',
      grading_type: 'points',
      points_possible: 100,
      due_at: 1.day.ago(now),
      submission_types: 'online_text_entry'
    )
  end

  def create_assignment_due_one_day(now)
    @assignment_due_one_day = @course.assignments.create!(
      title: 'assignment two',
      grading_type: 'points',
      points_possible: 100,
      due_at: 1.day.from_now(now),
      submission_types: 'online_text_entry'
    )
  end

  def create_assignment_due_one_week(now)
    @assignment_due_one_week = @course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 10,
      due_at: 1.week.from_now(now),
      submission_types: 'online_text_entry'
    )
  end

  def student_submits_assignments
    # as a student submit all assignments
    @assignment_past_due_day.submit_homework(@course.students.first, body: 'submitting my homework')
    @assignment_due_one_day.submit_homework(@course.students.first, body: 'submitting my homework')
    @assignment_due_one_week.submit_homework(@course.students.first, body: 'submitting my homework')
  end

  def teacher_grades_assignments
    # as a teacher grade the assignments
    @assignment_past_due_day.grade_student(@course.students.first, grade: String(Random.rand(1...100)), grader: @teacher)
    @assignment_due_one_day.grade_student(@course.students.first, grade: String(Random.rand(1...100)), grader: @teacher)
    @assignment_due_one_week.grade_student(@course.students.first, grade: String(Random.rand(1...10)), grader: @teacher)
  end
end

