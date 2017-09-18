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

require_relative '../../helpers/gradezilla_common'
require_relative '../../helpers/groups_common'
require_relative '../pages/gradezilla_page'

describe "Gradezilla - Assignment Column Options" do
  include_context "in-process server selenium tests"
  include GradezillaCommon
  include GroupsCommon

  before(:once) do
    course_with_teacher(active_all: true)

    # enroll three students
    3.times do |i|
      student = User.create!(name: "Student #{i+1}")
      student.register!
      @course.enroll_student(student).update!(workflow_state: 'active')
    end

    @assignment = @course.assignments.create!(
      title: "An Assignment",
      points_possible: 10,
      due_at: 1.day.from_now
    )

    @course.student_enrollments.collect(&:user).each do |student|
      @assignment.submit_homework(student, body: 'a body')
      @assignment.grade_student(student, grade: 10, grader: @teacher)
    end
  end

  before(:each) { user_session(@teacher) }

  describe "Sorting" do
    it "sorts by Missing", test_id: 3253336, priority: "1" do
      third_student = @course.students.find_by!(name: 'Student 3')
      @assignment.submissions.find_by!(user: third_student).update!(late_policy_status: "missing")
      Gradezilla.visit(@course)
      Gradezilla.click_assignment_header_menu(@assignment.id)
      Gradezilla.click_assignment_popover_sort_by('Missing')

      expect(Gradezilla.fetch_student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end

    it "sorts by Late" do
      third_student = @course.students.find_by!(name: 'Student 3')
      submission = @assignment.submissions.find_by!(user: third_student)
      submission.update!(submitted_at: 2.days.from_now) # make late
      Gradezilla.visit(@course)
      Gradezilla.click_assignment_header_menu(@assignment.id)
      Gradezilla.click_assignment_popover_sort_by('Late')

      expect(Gradezilla.fetch_student_names).to eq ["Student 3", "Student 1", "Student 2"]
    end
  end
end
