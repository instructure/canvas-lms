#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/student_grades_page'

describe "gradebook - logged in as a student" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  # Helpers
  def backend_group_helper
    Factories::GradingPeriodGroupHelper.new
  end

  def backend_period_helper
    Factories::GradingPeriodHelper.new
  end

  let(:student_grades_page) { StudentGradesPage.new }

  describe 'total point displays' do
    before(:each) do
      course_with_student_logged_in
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      assignment = @course.assignments.build(points_possible: 20)
      assignment.publish
      assignment.grade_student(@student, grade: 10, grader: @teacher)
      assignment.assignment_group.update(group_weight: 1)
      @course.show_total_grade_as_points = true
      @course.save!
    end

    it 'should display total grades as points', priority: "2", test_id: 164229 do
      student_grades_page.visit_as_student(@course)
      expect(student_grades_page.final_grade).to include_text("10")
    end

    it 'should display total "out of" point values' do
      student_grades_page.visit_as_student(@course)
      expect(student_grades_page.final_points_possible).to include_text("10.00 / 20.00")
    end
  end

  context 'when testing grading periods' do
    before do
      course_with_admin_logged_in
      student_in_course
    end

    context 'with one past and one current period' do
      past_period_name = "Past Grading Period"
      current_period_name = "Current Grading Period"
      past_assignment_name = "Past Assignment"
      current_assignment_name = "Current Assignment"

      before do
        # create term
        term = @course.root_account.enrollment_terms.create!
        @course.update_attributes(enrollment_term: term)

        # create group and periods
        group = backend_group_helper.create_for_account(@course.root_account)
        term.update_attribute(:grading_period_group_id, group)
        backend_period_helper.create_with_weeks_for_group(group, 4, 2, past_period_name)
        backend_period_helper.create_with_weeks_for_group(group, 1, -3, current_period_name)

        # create assignments
        @course.assignments.create!(due_at: 3.weeks.ago, title: past_assignment_name)
        @course.assignments.create!(due_at: 1.week.from_now, title: current_assignment_name)

        # go to student grades page
        student_grades_page.visit_as_teacher(@course, @student)
      end

      it 'should only show assignments that belong to the selected grading period', priority: "1", test_id: 2528639 do
        student_grades_page.select_period_by_name(past_period_name)
        expect_new_page_load { student_grades_page.click_apply_button }
        expect(student_grades_page.assignment_titles).to include(past_assignment_name)
        expect(student_grades_page.assignment_titles).not_to include(current_assignment_name)
      end
    end
  end
end
