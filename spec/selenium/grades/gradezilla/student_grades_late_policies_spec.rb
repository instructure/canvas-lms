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
require_relative '../pages/student_grades_page'

describe 'Late Policy statuses:' do
  include_context "in-process server selenium tests"
  include_context "late_policy_course_setup"
  include GradezillaCommon

  describe "grade display late policy pills" do

    before(:once) do
      # create course with students, assignments, submissions and grades
      init_course_with_students(1)
      create_course_late_policy
      create_assignments
      make_submissions
      grade_assignments
    end

    before(:each) do
      user_session(@teacher)
    end

    context 'with new gradebook disabled' do
      before(:once) do
        @course.disable_feature!(:new_gradebook)
      end

      before(:each) do
        StudentGradesPage.visit_as_teacher(@course, @course.students.first)
      end

      it 'missing submission does not have missing pill' do
        expect(f('#content')).not_to contain_css("#submission_#{@a2.id} .submission-missing-pill")
      end

      it 'late submission does not have late pill' do
        expect(f('#content')).not_to contain_css("#submission_#{@a1.id} .submission-late-pill")
      end
    end

    context 'with new gradebook enabled' do
      before(:once) do
        @course.enable_feature!(:new_gradebook)
      end

      before(:each) do
        StudentGradesPage.visit_as_teacher(@course, @course.students.first)
      end

      it 'missing submission has missing pill' do
        expect(StudentGradesPage.status_pill(@a2.id, 'missing')).to be_displayed
      end

      it 'late submission has late pill' do
        expect(StudentGradesPage.status_pill(@a1.id, 'late')).to be_displayed
      end

      it 'late submission has late penalty' do
        StudentGradesPage.show_details_button.click
        late_penalty_value = "-" + @course.students.first.submissions.find_by(assignment_id:@a1.id).points_deducted.to_s

        # the data from rails and data from ui are not in the same format
        expect(StudentGradesPage.submission_late_penalty_text(@a1.id).to_f.to_s).to eq late_penalty_value
      end

      it 'late submission has final grade' do
        StudentGradesPage.show_details_button.click
        final_grade_value = @course.students.first.submissions.find_by(assignment_id:@a1.id).published_grade

        expect(StudentGradesPage.late_submission_final_score_text(@a1.id)).to eq final_grade_value
      end
    end
  end
end
