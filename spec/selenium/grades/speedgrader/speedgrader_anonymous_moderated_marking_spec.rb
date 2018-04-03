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

  before(:each) do
    Account.default.enable_feature!(:anonymous_moderated_marking)
    Account.default.enable_feature!(:anonymous_marking)
    course_with_teacher_logged_in
    outcome_with_rubric
    @assignment = @course.assignments.create(
      name: 'some topic',
      points_possible: 10,
      submission_types: 'discussion_topic',
      description: 'a little bit of content'
    )
    student = user_with_pseudonym(
      name: 'first student',
      active_user: true,
      username: 'student@example.com',
      password: 'qwertyuiop'
    )
    @course.enroll_user(student, "StudentEnrollment", :enrollment_state => 'active')
    # create and enroll second student
    student_2 = user_with_pseudonym(
      name: 'second student',
      active_user: true,
      username: 'student2@example.com',
      password: 'qwertyuiop'
    )
    @course.enroll_user(student_2, "StudentEnrollment", :enrollment_state => 'active')
    Speedgrader.visit(@course.id, @assignment.id)
  end

  context "shows unique anonymous student IDs" do
    it "when teacher visits the page", priority: "1", test_id: 3481048 do
      skip('This is skeleton code that acts as AC for GRADE-895 which is WIP')
      student_names = Speedgrader.students_select_menu_list
      expect(student_names.first.text).to eq("Student 1")
      expect(student_names.last.text).to eq("Student 2")
    end

    it "when teacher selects a submission and refreshes page", priority: "1", test_id: 3481049 do
      skip('This is skeleton code that acts as AC for GRADE-895 which is WIP')
      Speedgrader.click_next_or_prev_student(:next)
      current_student = Speedgrader.selected_student
      expect(current_student.text).to eq("Student 2")
      refresh_page
      expect(current_student.text).to eq("Student 2")
    end
  end
end
