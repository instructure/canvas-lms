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

require_relative "../../common"
require_relative "../../helpers/speed_grader_common"
require_relative "../pages/speedgrader_page"

describe "SpeedGrader with Anonymous Moderated Marking enabled" do
  include_context "in-process server selenium tests"
  include SpeedGraderCommon

  before do
    Account.default.enable_feature!(:anonymous_moderated_marking)
    Account.default.enable_feature!(:anonymous_marking)
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create!(
      name: 'some topic',
      points_possible: 10,
      submission_types: 'discussion_topic',
      description: 'a little bit of content',
      anonymous_grading: true
    )
    student = user_with_pseudonym(
      name: 'Fen',
      active_user: true,
      username: 'student@example.com',
      password: 'qwertyuiop'
    )
    @course.enroll_user(student, "StudentEnrollment", enrollment_state: :active)
    # create and enroll second student
    student_2 = user_with_pseudonym(
      name: 'Zaz',
      active_user: true,
      username: 'student2@example.com',
      password: 'qwertyuiop'
    )
    @course.enroll_user(student_2, "StudentEnrollment", enrollment_state: :active)
    Speedgrader.visit(@course.id, @assignment.id)
  end

  context "shows unique anonymous student IDs" do
    it "when teacher visits the page", priority: "1", test_id: 3481048 do
      Speedgrader.students_dropdown_button.click
      student_names = Speedgrader.students_select_menu_list.map(&:text)
      expect(student_names).to eql ['Student 1', 'Student 2']
    end

    context "give a teacher as selected student two's submission" do
      before do
        Speedgrader.click_next_or_prev_student(:next)
        Speedgrader.students_dropdown_button.click
        @current_student = Speedgrader.selected_student
      end

      it "when teacher selects a submission and refreshes page", priority: "1", test_id: 3481049 do
        expect { refresh_page }.not_to change { Speedgrader.selected_student.text }.from('Student 2')
      end
    end
  end
end
