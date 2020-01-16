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

require_relative "../../common"
require_relative '../setup/gradebook_setup'

module WeightingSetup
  include GradebookSetup

  def weighted_grading_setup
    enrollment = add_teacher_and_student
    enrollment.workflow_state = 'active'
    enrollment.save!
    @course2 = Course.create!(name: "Course 2", account: Account.default, is_public: true)
    @course2.enroll_student(@student, allow_multiple_enrollments: true).accept(true)
    @course2.offer!

    @term_name = "First Term"

    create_weighted_grading_periods

    associate_course_to_term(@term_name)

    # assignement groups
    @ag1 = @course.assignment_groups.create!(name: 'assignment group one', group_weight: 60)
    @ag2 = @course.assignment_groups.create!(name: 'assignment group two', group_weight: 20)
    @ag3 = @course.assignment_groups.create!(name: 'assignment group three', group_weight: 20)

    # assignments
    create_assignments

    @a1.grade_student(@student, grade: 5, grader: @teacher)
    @a2.grade_student(@student, grade: 10, grader: @teacher)
    @a3.grade_student(@student, grade: 12, grader: @teacher)
    @a4.grade_student(@student, grade: 16, grader: @teacher)
  end

  def create_weighted_grading_periods()
    # :sigh: ... in the case of SRGB, the grading period dropdown behavior
    # is "interesting"... specifically 1. only the first change event
    # records your preference, 2. if its value doesn't change, no
    # preference is recorded and 3. if no preference is recorded, the
    # selected value can change from one page load to the next (say, if a
    # period becomes current due to crossing a minute boundary)
    #
    # so play it safe and make sure neither period will be current during
    # the specs. also why does SRGB need a page refresh to work at all?
    # :noideadog: (╯°□°)╯︵ ┻━┻

    backend_group_helper = Factories::GradingPeriodGroupHelper.new
    @gpg = backend_group_helper.create_for_account_with_term(Account.default, @term_name)
    @gpg.update(display_totals_for_all_grading_periods: true)

    backend_period_helper = Factories::GradingPeriodHelper.new
    @gp1 = backend_period_helper.create_for_group(@gpg, {
      start_date: 1.hour.from_now, end_date: 2.weeks.from_now, title: 'grading period one'
    })

    @gp2 = backend_period_helper.create_for_group(@gpg, {
      start_date: 2.weeks.ago, end_date: 1.day.ago, close_date: 1.week.from_now, title: 'grading period two'
    })
  end

  def create_assignments
    @a1 = @course.assignments.create!(
      title: 'assignment one',
      grading_type: 'points',
      points_possible: 10,
      assignment_group: @ag1,
      due_at: 1.week.from_now
    )

    @a2 = @course.assignments.create!(
      title: 'assignment two',
      grading_type: 'points',
      points_possible: 10,
      assignment_group: @ag1,
      due_at: 1.week.from_now
    )

    @a3 = @course.assignments.create!(
      title: 'assignment three',
      grading_type: 'points',
      points_possible: 20,
      assignment_group: @ag2,
      due_at: 1.week.ago
    )

    @a4 = @course.assignments.create!(
      title: 'assignment four',
      grading_type: 'points',
      points_possible: 40,
      assignment_group: @ag3,
      due_at: 1.week.ago
    )
  end
end
