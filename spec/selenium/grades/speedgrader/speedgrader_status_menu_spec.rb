# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../../helpers/assignments_common"
require_relative "../../helpers/gradebook_common"
require_relative "../pages/speedgrader_page"

describe "speed grader" do
  include_context "in-process server selenium tests"
  include_context "late_policy_course_setup"
  include AssignmentsCommon

  before(:once) do
    course_with_teacher(name: "Teacher1", active_user: true, active_enrollment: true, active_course: true).user
    student_in_course(name: "Student1", active_all: true).user

    create_course_late_policy
    @assignment = @course.assignments.create!(
      name: "foo",
      points_possible: 10,
      submission_types: "online_url",
      due_at: 1.day.ago
    )
  end

  context "status menu" do
    it "loads with none status and appropriately handles transition to late status" do
      @assignment.submit_homework(@student, body: "Attempt 1", submitted_at: 2.days.ago)
      @assignment.grade_student(@student, grade: 8, grader: @teacher)

      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)

      expect(Speedgrader.status_menu_btn).to be_displayed
      Speedgrader.status_menu_btn.click
      expect(Speedgrader.status_menu_option("None").attribute("aria-checked")).to eq "true"

      Speedgrader.status_menu_option("Late").click
      expect(Speedgrader.submission_status_pill("late")).to be_displayed
      expect(Speedgrader.time_late_input).to be_displayed

      replace_content(Speedgrader.time_late_input, 1, tab_out: true)

      expect(Speedgrader.final_late_policy_grade_text).to eq "7"
      submission = Submission.find_by(user_id: @student.id)
      expect(submission.grade).to eq "7"
    end

    it "loads with missing status and properly handles the transition to excused status" do
      user_session(@teacher)
      Speedgrader.visit(@course.id, @assignment.id)

      expect(Speedgrader.status_menu_btn).to be_displayed
      Speedgrader.status_menu_btn.click
      expect(Speedgrader.status_menu_option("Missing").attribute("aria-checked")).to eq "true"

      Speedgrader.status_menu_option("Excused").click
      expect(Speedgrader.grade_value).to eq "EX"
      submission = Submission.find_by(user_id: @student.id)
      expect(submission.excused).to be true
    end
  end
end
