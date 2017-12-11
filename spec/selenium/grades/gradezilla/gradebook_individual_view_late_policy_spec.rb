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

require_relative '../pages/gradezilla_individual_view_page'
require_relative '../../helpers/gradezilla_common'

describe 'Late Policies:' do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  include_context "late_policy_course_setup"

  before(:once) do
    # create course with students, assignments, submissions and grades
    init_course_with_students(1)
    create_course_late_policy
    create_assignments
    make_submissions
    grade_assignments
  end

  context "grade detail tray other" do
    before(:each) do
      user_session(@teacher)
      GradezillaIndividualViewPage.visit(@course.id)
    end

    it 'missing submission has missing pill' do
      GradezillaIndividualViewPage.select_assignment(@a2)
      GradezillaIndividualViewPage.select_student(@course.students.first)

      expect(GradezillaIndividualViewPage.status_pill('missing')).to be_displayed
    end

    it 'late submission has late pill' do
      GradezillaIndividualViewPage.select_assignment(@a1)
      GradezillaIndividualViewPage.select_student(@course.students.first)

      expect(GradezillaIndividualViewPage.status_pill('late')).to be_displayed
    end

    it "late submission has late penalty" do
      GradezillaIndividualViewPage.select_assignment(@a1)
      GradezillaIndividualViewPage.select_student(@course.students.first)

      late_penalty_value = "-" + @course.students.first.submissions.find_by(assignment_id:@a1.id).points_deducted.to_s

      # the data from rails and data from ui are not in the same format
      expect(GradezillaIndividualViewPage.late_penalty_text.to_f.to_s).to eq late_penalty_value
    end

    it "late submission has final grade" do
      GradezillaIndividualViewPage.select_assignment(@a1)
      GradezillaIndividualViewPage.select_student(@course.students.first)

      final_grade_value = @course.students.first.submissions.find_by(assignment_id:@a1.id).published_grade
      expect(GradezillaIndividualViewPage.late_policy_final_grade_text).to eq final_grade_value
    end
  end
end
