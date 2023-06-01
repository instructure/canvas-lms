# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
require_relative "../pages/moderate_page"
require_relative "../pages/speedgrader_page"

describe "Moderated Marking" do
  include_context "in-process server selenium tests"

  let_once(:account) do
    account = Account.default
    account.enable_feature!(:moderated_grading)
    account
  end

  let_once(:course) do
    course = account.courses.create!
    course.offer!
    course
  end

  let_once(:teacher) { teacher_in_course(course:, active_enrollment: true).user }
  let_once(:ta) { ta_in_course(course:, active_enrollment: true).user }
  let_once(:student) { student_in_course(course:, active_enrollment: true).user }

  let_once(:assignment) do
    course.assignments.create!(
      final_grader: teacher,
      grader_count: 2,
      moderated_grading: true,
      points_possible: 10,
      submission_types: :online_text_entry,
      title: "Moderated Assignment"
    )
  end

  context "moderation page" do
    it "allows viewing provisional grades and releasing final grade" do
      rubric = outcome_with_rubric
      association = rubric.associate_with(assignment, course, purpose: "grading")
      association.update!(use_for_grading: true)
      assignment.submit_homework(student, submission_type: :online_text_entry, body: :asdf)

      user_session(ta)
      Speedgrader.visit(course.id, assignment.id)

      scroll_into_view(".toggle_full_rubric")
      f(".toggle_full_rubric").click
      f('td[data-testid="criterion-points"] input').send_keys("3")
      Speedgrader.expand_right_pane
      fj("span:contains('Amazing'):visible").click
      wait_for_ajaximations
      scroll_into_view(".save_rubric_button")
      f("#rubric_full .save_rubric_button").click
      wait_for_ajaximations

      Speedgrader.grade_input.send_keys 10
      Speedgrader.grade_input.send_keys :tab
      wait_for_ajaximations

      user_session(teacher)
      ModeratePage.visit(course.id, assignment.id)
      ModeratePage.select_provisional_grade_for_student_by_position(student, 0)
      ModeratePage.click_release_grades_button
      accept_alert
      expect_instui_flash_message "Grades were successfully released to the gradebook"
      wait_for_ajax_requests
    end
  end
end
