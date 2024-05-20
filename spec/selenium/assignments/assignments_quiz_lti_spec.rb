# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/assignments_common"

describe "quiz LTI assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  before do
    course_with_teacher_logged_in
    provision_quizzes_next @course
    @course.root_account.enable_feature!(:quizzes_next)
    @course.enable_feature!(:quizzes_next)
    @course.require_assignment_group
    @tool = @course.context_external_tools.create!(
      name: "Quizzes.Next",
      consumer_key: "test123",
      shared_secret: "test123",
      tool_id: "Quizzes 2",
      url: "http://example.com/launch"
    )
  end

  # EVAL-3711 Remove this test when instui_nav feature flag is removed
  it "creates an LTI assignment", priority: "2" do
    get "/courses/#{@course.id}/assignments"
    f(".new_quiz_lti").click

    f("#assignment_name").send_keys("LTI quiz")
    submit_assignment_form

    assignment = @course.assignments.last
    expect(assignment).to be_present
    expect(assignment.quiz_lti?).to be true
  end

  it "creates an LTI assignment with the Instui Nav feature flag on", priority: "2" do
    @course.root_account.enable_feature!(:instui_nav)
    get "/courses/#{@course.id}/assignments"
    f("[data-testid='new_quiz_button']").click

    f("#assignment_name").send_keys("LTI quiz")
    submit_assignment_form

    assignment = @course.assignments.last
    expect(assignment).to be_present
    expect(assignment.quiz_lti?).to be true
  end
end
